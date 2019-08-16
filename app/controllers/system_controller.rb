class SystemController < ApplicationController

  def status
    render json: { meta: System.info }
  rescue StandardError => e
    render json: jsonapi_error('Error during status fetch', e.message, 500), status: 500
  end

  def reset
    # FIXME: Temporary workaround for Display app
    StateCache.s.resetting = true

    # Stop scheduler to prevent running jobs from calling extension methods that are no longer available.
    Rufus::Scheduler.s.shutdown(:kill)

    reset_line = Terrapin::CommandLine.new('sh', "#{Rails.root}/reset.sh :env")
    reset_line.run(env: Rails.env)

    # All good until here, send the reset email.
    SettingExecution::Personal.send_reset_email

    Thread.new do
      # Wait a bit to ensure 204 response from parent thread is properly sent.
      sleep 2
      # Disconnect from Wifi networks if configured, disable LAN to force setup through AP
      SettingExecution::Network.reset
      SettingExecution::Network.disable_lan

      MirrOSApi::Application.load_tasks
      Rake::Task['db:recycle'].invoke

      Rails.env.development? ? System.restart_application : System.reboot
      Thread.exit
    end

    head :no_content

  rescue StandardError => e
    StateCache.s.resetting = false
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

  def run_setup
    user_time = Integer(params[:reference_time])
    System.change_system_time(user_time)
    raise ArgumentError, 'Missing required setting.' unless System.setup_completed?

    StateCache.s.configured_at_boot = true
    # FIXME: This is a temporary workaround to differentiate between
    # initial setup before first connection attempt and subsequent network problems.
    # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands

    connect_to_network
    online_or_raise

    # System has internet connectivity, complete seed and send setup mail
    # TODO: Handle errors in thread and take action if required
    Thread.new do
      sleep 2
      SettingExecution::Personal.send_setup_email
      create_default_cal_instances
      create_default_feed_instances
      ActiveRecord::Base.clear_active_connections!
    end

    render json: { meta: System.info }
  rescue StandardError => e
    render json: jsonapi_error('Error during setup', e.message, 500),
           status: :internal_server_error
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
  # TODO: This is currently not used since all extensions are bundled, however it can be useful for custom installations that use different gemservers.
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
    render json: jsonapi_error('Error while sending debug report', e.message, 500),
           status: :internal_server_error
  end

  private

  def connect_to_network
    conn_type = SettingsCache.s[:network_connectiontype]
    case conn_type
    when 'wlan'
      SettingExecution::Network.connect
    when 'lan'
      SettingExecution::Network.close_ap if SettingExecution::Network.ap_active?
      SettingExecution::Network.enable_lan
      SettingExecution::Network.reset
    else
      Rails.logger.error "Setup encountered invalid connection type #{conn_type}"
      raise ArgumentError, "invalid connection type #{conn_type}"
    end
  end

  def online_or_raise
    retries = 0
    until retries > 5 || System.online?
      sleep 5
      retries += 1
    end
    raise StandardError, 'Could not connect to the internet within 25 seconds' if retries > 5
  end

  def create_default_cal_instances
    locale = SettingsCache.s[:system_language].empty? ? 'enGb' : SettingsCache.s[:system_language]
    feed_settings = default_holiday_calendar(locale)

    ActiveRecord::Base.transaction do
      # Skip callbacks to avoid HTTP calls in meta generation
      SourceInstance.skip_callback :create, :after, :set_meta
      calendar_source = SourceInstance.new(
        source: Source.find_by(slug: 'ical'),
        configuration: { "url": feed_settings[:url] },
        options: [
          {
            uid: 'e4ffacba5591440a14a08eac7aade57c603e17c0_0',
            display: feed_settings[:title]
          }
        ],
        title: feed_settings[:title]
      )
      calendar_source.save!(validate: false)
      SourceInstance.set_callback :create, :after, :set_meta

      calendar_widget = WidgetInstance.find_by(widget_id: 'calendar_event_list')
      calendar_widget.update(title: feed_settings[:title])
      InstanceAssociation.create!(
        configuration: {
          "chosen": ['e4ffacba5591440a14a08eac7aade57c603e17c0_0']
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
