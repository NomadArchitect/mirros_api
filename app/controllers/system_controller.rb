# frozen_string_literal: true

class SystemController < ApplicationController
  def status
    render json: { meta: System.info }
  rescue StandardError => e
    render json: jsonapi_error('Error during status fetch', e.message, 500),
           status: :internal_server_error
  end

  def reset
    # FIXME: Temporary workaround for Display app
    StateCache.refresh_resetting true
    ActionCable.server.broadcast 'status', payload: ::System.info

    # Stop scheduler to prevent running jobs from calling extension methods that are no longer available.
    Rufus::Scheduler.s.shutdown(:kill)

    reset_line = Terrapin::CommandLine.new('sh', "#{Rails.root.join('reset.sh')} :env")
    reset_line.run(env: Rails.env)

    # All good until here, send the reset email.
    SettingExecution::Personal.send_reset_email

    Thread.new do
      # Wait a bit to ensure 204 response from parent thread is properly sent.
      sleep 2
      # Disconnect from Wifi networks if configured, disable LAN to force setup through AP
      SettingExecution::Network.reset
      SettingExecution::Network.disable_lan
      SettingExecution::Network.remove_predefined_connections

      MirrOSApi::Application.load_tasks
      Rake::Task['db:recycle'].invoke
      Rake::Task['mirros:setup:network_connections'].invoke

      Rails.env.development? ? System.restart_application : System.reboot
      Thread.exit
    end

    head :no_content
  rescue StandardError => e
    StateCache.refresh_resetting false
    Rails.logger.error e.message
    render json: jsonapi_error('Error during reset', e.message, 500),
           status: :internal_server_error
    # TODO: Remove installed extensions as well, since they're no longer registered in the database
  end

  def reboot
    System.reboot
  rescue StandardError => e
    render json: jsonapi_error('Error during reboot attempt', e.message, 500),
           status: :internal_server_error
  end

  def shut_down
    System.shut_down
  rescue StandardError => e
    render json: jsonapi_error('Error during shutdown attempt', e.message, 500),
           status: :internal_server_error
  end

  def reload_browser
    System.reload_browser
  rescue StandardError => e
    message = if e.message.include?('AppArmor policy prevents')
                'snap interface not connected. Please connect to your glancr via SSH and run
`snap connect mirros-one:dbus-cogctl wpe-webkit-mir-kiosk:dbus-cogctl`'
              else
                e.message
              end
    render json: jsonapi_error('Error while reloading browser', message, 500),
           status: :internal_server_error
  end

  # @param [Hash] options
  # @option options [String] :reference_time epoch timestamp in milliseconds
  def run_setup(options = { create_defaults: true })
    Rufus::Scheduler.s.pause
    ref_time = params[:reference_time]
    user_time = begin
                  ref_time.is_a?(Integer) ? ref_time / 1000 : Time.strptime(ref_time, '%Q').to_i
                rescue ArgumentError, TypeError => e
                  Rails.logger.warn "#{__method__} using current system time. #{ref_time}: #{e.message}"
                  Time.current.to_i
                end
    System.change_system_time(user_time)
    unless System.setup_completed?
      Rails.logger.error 'Aborting setup, missing a value'
      raise ArgumentError, 'Missing required setting.'
    end

    SettingExecution::Network.connect

    # TODO: Handle errors in thread and take action if required
    Thread.new(options) do |opts|
      sleep 2
      SettingExecution::Personal.send_setup_email
      if opts[:create_defaults]
        load_defaults_file
        create_widget_instances
        create_default_cal_instances
        create_default_feed_instances
      end
      Scheduler.daily_reboot
      ActiveRecord::Base.clear_active_connections!
    end

    render json: { meta: System.info }, status: :accepted
  rescue StandardError => e
    Rails.logger.error "#{__method__} #{e.message}"
    # e.g. wrong WiFi password -> no error during connection, but not online
    SettingExecution::Network.open_ap
    render json: jsonapi_error('Error during setup', e.message, 500),
           status: :internal_server_error
  ensure
    Rufus::Scheduler.s.resume
  end

  # TODO: Respond with appropriate status codes in addition to success
  def setting_execution
    executor = "SettingExecution::#{params[:category].capitalize}".safe_constantize
    if executor.respond_to?(params[:command])
      begin
        result = if executor.method(params[:command]).arity.positive?
                   executor.send(params[:command], *params)
                 else
                   executor.send(params[:command])
                 end
        render json: { success: true, result: result }
      rescue StandardError => e
        render json: jsonapi_error(
          "error while executing #{params[:category]}/#{params[:command]}",
          e.message,
          500
        ), status: :internal_server_error
      end
    else
      render json: jsonapi_error(
        "error while executing #{params[:category]}/#{params[:command]}",
        "#{params[:action]} is not a valid action for "\
               "#{params[:category]} settings. Valid actions are: "\
               "#{executor.methods}",
        500
      ), status: :internal_server_error
    end
  end

  # @return [JSON] JSON:API formatted list of all available extensions for the given extension type
  # TODO: This is currently not used since all extensions are bundled, however it can be useful for custom installations
  # that use different gem servers.
  def fetch_extensions
    render json: HTTParty.get(
      "http://#{MirrOSApi::Application::GEM_SERVER}/list/#{params[:type]}",
      timeout: 5
    )
  rescue StandardError => e
    Rails.logger.error "Could not fetch #{params[:type]} list from #{MirrOSApi::Application::GEM_SERVER}: #{e.message}"
    render json: jsonapi_error(
      "Could not fetch #{params[:type]} list",
      e.message,
      504
    ), status: :gateway_timeout
  end

  def log_client_error
    err_string = "
----------------------------------
Message: #{params[:error]}
Vue instance: #{params[:instance]}
stack trace:
#{params[:stack]}
----------------------------------
    "
    ClientLogger.error err_string
  end

  # Checks if a logfile with the given name exists in the Rails log directory
  # and returns it.
  # @return [FileBody] Content of the requested log file
  def fetch_logfile
    logfile = Rails.root.join('log', "#{params[:logfile]}.log")

    if Pathname.new(logfile).exist?
      send_file(logfile)
    else
      render json: jsonapi_error(
        'Logfile not found',
        "Could not find #{params[:logfile]}",
        404
      ), status: :not_found
    end
  end

  def generate_system_report
    render json: DebugReport.system_report
  end

  def send_debug_report
    report = DebugReport.new(params[:title].to_s, params[:description].to_s, params[:email].to_s)
    res = report.send_mail
    head res.code
  rescue StandardError => e
    render json: jsonapi_error('Error while sending debug report', e.message, 500),
           status: :internal_server_error
  end

  def backup_settings
    Rufus::Scheduler.s.pause

    if ENV['SNAP_DATA'].nil?
      head :no_content
    else
      # create-backup script is included in mirros-one-snap repository
      line = Terrapin::CommandLine.new('create-backup')
      backup_location = Pathname.new("#{ENV['SNAP_DATA']}/#{line.run.chomp}")
      send_file(backup_location) if backup_location.exist?
    end

    Rufus::Scheduler.s.resume
  end

  def restore_settings
    return if ENV['SNAP_DATA'].nil?

    Rufus::Scheduler.s.stop
    StateCache.refresh_resetting true
    SettingExecution::Network.close_ap # Would also be closed by run_setup, but we don't want it open that long

    # TODO: Create backup of current state to roll back if necessary
    backup_file = params[:backup_file]
    FileUtils.mv backup_file.tempfile, "#{ENV['SNAP_DATA']}/#{backup_file.original_filename}"
    # restore-backup script is included in mirros-one-snap repository
    # FIXME: Ignore return code 1 until proper rollbacks are implemented.
    # In installations with SNAP_VERSION < 1.8.0, my.cnf didn't contain a password. Calling mysql with -p triggers a
    # warning which Terrapin interprets as a fatal error.
    line = Terrapin::CommandLine.new(
      'restore-backup',
      ':backup_file', expected_outcodes: [0, 1]
    )
    line.run(backup_file: "#{ENV['SNAP_DATA']}/#{backup_file.original_filename}")

    # Forces SettingsCache updates to satisfy `System.setup_completed?` check. TODO: Brittle, should be refactored
    Setting.find_by(slug: 'personal_email').save!
    Setting.find_by(slug: 'network_connectiontype').save!
    Setting.find_by(slug: 'network_ssid').save!
    Setting.find_by(slug: 'network_password').save!
    Setting.find_by(slug: 'system_timezone').save! # Apply timezone setting

    run_setup(
      create_defaults: false,
      params: { reference_time: params[:reference_time] }
    )
    System.reboot
  end

  private

  # Creates the default widget instances, based on the current display layout.
  def create_widget_instances
    orientation = SystemState.dig(variable: 'client_display', key: 'orientation') || 'portrait'
    default_board = Board.find_by(title: 'default')
    instances = []
    @defaults['widget_instances'].each do |slug, config|
      instances << config.merge(
        { widget: Widget.find_by(slug: slug), position: config['position'][orientation], board: default_board })
    end
    WidgetInstance.create(instances)
  end

  # Creates the default holiday calendar configuration.
  # @see SystemController.create_widget_instances must run before to create the widget instance.
  def create_default_cal_instances
    locale = SettingsCache.s[:system_language].empty? ? 'enGb' : SettingsCache.s[:system_language]
    calendar_settings = default_holiday_calendar(locale)

    ActiveRecord::Base.transaction do
      calendar_source = SourceInstance.new(
        source: Source.find_by(slug: 'ical'),
        configuration: { "url": calendar_settings[:url] }
      )
      calendar_source.save!(validate: false)
      calendar_source.update(
        options: [
          { uid: calendar_source.options.first['uid'], display: calendar_settings[:title] }
        ],
        title: calendar_settings[:title]
      )

      calendar_widget = WidgetInstance.find_by(widget_id: 'calendar_event_list')
      calendar_widget.update(title: calendar_settings[:title])
      InstanceAssociation.create!(
        configuration: {
          "chosen": [calendar_source.options.first['uid']]
        },
        group: Group.find_by(slug: 'calendar'),
        widget_instance: calendar_widget,
        source_instance: calendar_source
      )
    end
  rescue StandardError => e
    Rails.logger.error "Error during calendar instance creation: #{e.message}"
  end

  def create_default_feed_instances
    locale = SettingsCache.s[:system_language].empty? ? 'enGb' : SettingsCache.s[:system_language]
    ActiveRecord::Base.transaction do
      SourceInstance.skip_callback :create, :after, :set_meta
      newsfeed_source = SourceInstance.new(
        source: Source.find_by(slug: 'rss_feeds'),
        title: 'glancr: Welcome Screen',
        configuration: {
          "feedUrl": "https://api.glancr.de/welcome/mirros-welcome-#{locale}.xml"
        },
        options: [
          { uid: "https://api.glancr.de/welcome/mirros-welcome-#{locale}.xml",
            display: 'glancr: Welcome Screen' }
        ]
      )
      newsfeed_source.save!(validate: false)
      SourceInstance.set_callback :create, :after, :set_meta

      InstanceAssociation.create!(
        configuration: { "chosen": ["https://api.glancr.de/welcome/mirros-welcome-#{locale}.xml"] },
        group: Group.find_by(slug: 'newsfeed'),
        widget_instance: WidgetInstance.find_by(widget_id: 'ticker'),
        source_instance: SourceInstance.find_by(source_id: 'rss_feeds')
      )
    end
  rescue StandardError => e
    Rails.logger.error "Error during calendar instance creation: #{e.message}"
  end

  # Generates locale-dependent configuration for the default holiday calendar iCal source instance.
  # @param [string] locale A valid system locale, @see app/lib/setting_options.yaml at system_language
  def default_holiday_calendar(locale)
    yaml = @defaults['source_instances']['holiday_calendar']
    {
      url: yaml['configuration']['url'] % yaml['locale_fragments'][locale],
      title: yaml['configuration']['title'] % yaml['titles'][locale]
    }
  end

  # Loads the default extension configuration from a YAML file to reduce bloat here.
  def load_defaults_file
    return unless @defaults.nil?

    @defaults = YAML.load_file(Rails.root.join('app/lib/default_extensions.yml'))
  end

  def jsonapi_error(title, msg, code)
    # FIXME: Can we reuse something for this mapping?
    status = {
      400 => :bad_request,
      404 => :not_found,
      500 => :internal_server_error,
      504 => :gateway_timeout
    }[code]
    {
      errors: [
        JSONAPI::Error.new(title: title, detail: msg, code: code, status: status)
      ]
    }
  end
end
