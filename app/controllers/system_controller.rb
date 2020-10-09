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
                  ref_time.is_a?(Integer) ? ref_time/1000 : Time.strptime(ref_time, '%Q').to_i
                rescue ArgumentError, TypeError => e
                  Rails.logger.warn "#{__method__} using current system time. #{ref_time}: #{e.message}"
                  Time.current.to_i
                end
    System.change_system_time(user_time)
    unless System.setup_completed?
      Rails.logger.error 'Aborting setup, missing a value'
      raise ArgumentError, 'Missing required setting.'
    end

    connect_to_network
    online_or_raise

    # TODO: Handle errors in thread and take action if required
    Thread.new(options) do |opts|
      sleep 2
      SettingExecution::Personal.send_setup_email
      if opts[:create_defaults]
        create_default_cal_instances
        create_default_feed_instances
      end
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
    render json: DebugReport.installed_extensions.merge(DebugReport.active_instances)
  end

  def send_debug_report
    report = DebugReport.new(params[:title].to_s, params[:description].to_s, params[:email].to_s)
    res = report.send
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
    Thread.new(params[:backup_file]) do |backup_file|
      FileUtils.mv backup_file.tempfile, "#{ENV['SNAP_DATA']}/#{backup_file.original_filename}"
      # restore-backup script is included in mirros-one-snap repository
      # FIXME: Ignore return code 1 until proper rollbacks are implemented.
      # In installations where the initial snap version was <= 0.13.2,
      # my.cnf didn't contain a password. Calling mysql with -p triggers a warning
      # which Terrapin interprets as a fatal error.
      line = Terrapin::CommandLine.new(
        'restore-backup',
        ':backup_file', expected_outcodes: [0, 1]
      )
      line.run(backup_file: backup_file.original_filename)
      Setting.find_by(slug: 'system_timezone').save # Apply timezone setting
      run_setup(
        create_defaults: false,
        params: { reference_time: Time.current }
      )
      System.reboot
    end

    head :no_content
  end

  private

  def connect_to_network
    conn_type = SettingsCache.s[:network_connectiontype]
    case conn_type
    when 'wlan'
      SettingExecution::Network.connect
    when 'lan'
      SettingExecution::Network.enable_lan
      SettingExecution::Network.close_ap
    else
      raise ArgumentError, "invalid connection type #{conn_type}"
    end
  end

  def online_or_raise
    retries = 0
    until retries > 24 || System.online?
      sleep 5
      retries += 1
    end

    if retries > 24
      raise StandardError, 'Could not connect to the internet within two minutes'
    end
  end

  def create_default_cal_instances
    locale = SettingsCache.s[:system_language].empty? ? 'enGb' : SettingsCache.s[:system_language]
    feed_settings = default_holiday_calendar(locale)

    ActiveRecord::Base.transaction do
      calendar_source = SourceInstance.new(
        source: Source.find_by(slug: 'ical'),
        configuration: { "url": feed_settings[:url] }
      )
      calendar_source.save!(validate: false)
      calendar_source.update(
        options: [
          {
            uid: calendar_source.options.first['uid'],
            display: feed_settings[:title]
          }
        ],
        title: feed_settings[:title]
      )

      calendar_widget = WidgetInstance.find_by(widget_id: 'calendar_event_list')
      calendar_widget.update(title: feed_settings[:title])
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

  # noinspection SpellCheckingInspection
  def default_holiday_calendar(locale)
    fragments = {
      url: {
        enGb: 'en.uk',
        deDe: 'de.german',
        frFr: 'fr.french',
        esEs: 'es.spain',
        plPl: 'pl.polish',
        koKr: 'ko.south_korea'
      }[locale.to_sym],
      title: {
        enGb: 'UK Holidays',
        deDe: 'Deutsche Feiertage',
        frFr: 'vacances en France',
        esEs: 'Vacaciones en España',
        plPl: 'Polskie święta',
        koKr: '한국의 휴일'
      }[locale.to_sym]
    }
    holiday_calendar_hash(fragments)
  end

  def holiday_calendar_hash(fragments)
    {
      url: "https://calendar.google.com/calendar/ical/#{fragments[:url]}%23holiday%40group.v.calendar.google.com/public/basic.ics",
      title: "#{fragments[:title]} (Google)"
    }
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
