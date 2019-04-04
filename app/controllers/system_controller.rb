class SystemController < ApplicationController

  def status
    render json: {meta: System.info}
  rescue StandardError => e
    render json: jsonapi_error('Error during status fetch', e.message, 500), status: 500
  end

  def reset
    # FIXME: Temporary workaround for Display app
    StateCache.s.resetting = true

    # Stop scheduler to prevent running jobs from calling extension methods that are no longer available.
    DataRefresher.scheduler.shutdown(:kill)

    reset_line = Terrapin::CommandLine.new('sh', "#{Rails.root}/reset.sh :env")
    reset_line.run(env: Rails.env)

    # All good until here, send the reset email.
    SettingExecution::Personal.send_reset_email

    Thread.new do
      # Wait a bit to ensure 204 response from parent thread is properly sent.
      sleep 2
      # Disconnect from Wifi networks if configured
      SettingExecution::Network.reset unless SettingsCache.s[:network_connectiontype].eql? 'lan'

      MirrOSApi::Application.load_tasks
      Rake::Task['db:recycle'].invoke

      Rails.env.development? ? System.restart_application : System.reboot
      Thread.exit
    end

    head :no_content

  rescue StandardError => e
    StateCache.s.resetting = false
    render json: jsonapi_error('Error during reset', e.message, 500), status: 500
    # TODO: Remove installed extensions as well, since they're no longer registered in the database
  end

  def reboot
    System.reboot
  rescue StandardError => e
    render json: jsonapi_error('Error during reboot attempt', e.message, 500), status: 500
  end

  def run_setup
    user_time = params[:reference_time]
    System.change_system_time(user_time)

    StateCache.s.configured_at_boot = true
    # FIXME: This is a temporary workaround to differentiate between
    # initial setup before first connection attempt and subsequent network problems.
    # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands

    # TODO: clean this up
    case SettingsCache.s[:network_connectiontype]
    when 'wlan'
      begin
        result = SettingExecution::Network.connect
        success = true
      rescue ArgumentError, Terrapin::ExitStatusError => e
        result = e.message
        success = false
      end
    when 'lan'
      SettingExecution::Network.close_ap
      result = SettingExecution::Network.enable_lan
      success = true
    else
      conn_type = SettingsCache.s[:network_connectiontype]
      # TODO: Can we use some sort of args variable here?
      Rails.logger.error "Setup encountered invalid connection type '#{conn_type}'"
      raise ArgumentError, "invalid connection type '#{conn_type}'"
    end

    # Test online status
    retries = 0
    until retries > 5 || System.online?
      sleep 5
      retries += 1
    end

    if success && System.online?
      # TODO: Handle errors in thread and take action if required
      Thread.new do
        sleep 2
        SettingExecution::Personal.send_setup_email
        System.toggle_timesyncd_ntp(true)

        create_default_cal_instances
        create_default_feed_instances
      end

    else
      message = "Setup failed!\n"
      message << "Could not connect to WiFi, reason: #{result}\n" unless success
      message << 'Could not connect to the internet'
      Rails.logger.error message
    end
    render json: {success: success, result: result}
  rescue StandardError => e
    render json: jsonapi_error('Error while sending debug report', e.message, 500), status: 500
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
        render json: {success: true, result: result}
      rescue StandardError => e
        render json: jsonapi_error(
          "error while executing #{params[:category]}/#{params[:command]}",
          e.message,
          500
        ), status: 500
      end
    else
      render json: jsonapi_error(
        "error while executing #{params[:category]}/#{params[:command]}",
        "#{params[:action]} is not a valid action for "\
               "#{params[:category]} settings. Valid actions are: "\
               "#{executor.methods}",
        500
      ), status: 500
    end
  end

  # @return [JSON] JSON:API formatted list of all available extensions for the given extension type
  def fetch_extensions
    # FIXME: Use API_HOST as well once migration is done.
    render json: HTTParty.get(
      "http://gems.marco-roth.ch/list/#{params[:type]}",
      timeout: 5
    )
  rescue SocketError, Net::OpenTimeout => e
    Rails.logger.error "Error while fetching extension lists: #{e.message}"
    render json: jsonapi_error(
      'error while fetching extensions',
      e.message,
      504
    ), status: 504
  end

  # Checks if a logfile with the given name exists in the Rails log directory
  # and returns it.
  # @return [FileBody] Content of the requested log file
  def fetch_logfile
    logfile = "#{Rails.root}/log/#{params[:logfile]}.log"

    if Pathname.new(logfile).exist?
      send_file(logfile)
    else
      render json: jsonapi_error(
        'Logfile not found',
        "Could not find #{params[:logfile]}",
        404
      )
    end
  end

  def generate_system_report
    render json: DebugReport.installed_extensions.merge(DebugReport.active_instances)
  end

  def send_debug_report
    report = DebugReport.new(params[:title], params[:description], params[:email])
    res = report.send
    head res.code
  rescue StandardError => e
    render json: jsonapi_error('Error while sending debug report', e.message, 500), status: 500
  end

  private

  def create_default_cal_instances
    locale = SettingsCache.s[:system_language].empty? ? 'enGb' : SettingsCache.s[:system_language]
    feed_settings = default_holiday_calendar(locale)

    ActiveRecord::Base.transaction do
      # Skip callbacks to avoid HTTP calls in meta generation
      SourceInstance.skip_callback :create, :after, :set_meta
      calendar_source = SourceInstance.create(
        source: Source.find_by_slug('ical'),
        configuration: {"url": feed_settings[:url]},
        options: [{
                    uid: 'e4ffacba5591440a14a08eac7aade57c603e17c0_0',
                    display: feed_settings[:title]
                  }]
      )
      calendar_source.update(title: feed_settings[:title])
      SourceInstance.set_callback :create, :after, :set_meta

      calendar_widget = WidgetInstance.find_by_widget_id('calendar_event_list')
      calendar_widget.update(title: feed_settings[:title])
      InstanceAssociation.create(
        configuration: {
          "chosen": ['e4ffacba5591440a14a08eac7aade57c603e17c0_0']
        },
        group: Group.find_by_slug('calendar'),
        widget_instance: calendar_widget,
        source_instance: calendar_source
      )
    end
  end

  def create_default_feed_instances
    locale = SettingsCache.s[:system_language].empty? ? 'enGb' : SettingsCache.s[:system_language]

    SourceInstance.skip_callback :create, :after, :set_meta
    newsfeed_source = SourceInstance.new(
      source: Source.find_by_slug('rss_feeds'),
      title: 'glancr: Welcome Screen',
      configuration: {"feedUrl": "https://api.glancr.de/welcome/mirros-welcome-#{locale}.xml"},
      options: [{uid: "https://api.glancr.de/welcome/mirros-welcome-#{locale}.xml", display: 'glancr: Welcome Screen'}]
    )
    newsfeed_source.save(validate: false)
    SourceInstance.set_callback :create, :after, :set_meta

    InstanceAssociation.create(
      configuration: {"chosen": ["https://api.glancr.de/welcome/mirros-welcome-#{locale}.xml"]},
      group: Group.find_by_slug('newsfeed'),
      widget_instance: WidgetInstance.find_by_widget_id('ticker'),
      source_instance: SourceInstance.find_by_source_id('rss_feeds')
    )
  end

  def default_holiday_calendar(locale)
    fragments = {
      url: {
        enGb: 'en.uk',
        deDe: 'de.german',
        frFr: 'fr.french',
        esEs: 'es.spain',
        plPl: 'pl.polish',
        koKr: 'ko.south_korea'
      }[locale],
      title: {
        enGb: 'UK Holidays',
        deDe: 'Deutsche Feiertage',
        frFr: 'vacances en France',
        esEs: 'Vacaciones en España',
        plPl: 'Polskie święta',
        koKr: '한국의 휴일'
      }[locale]
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
