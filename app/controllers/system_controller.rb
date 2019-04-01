class SystemController < ApplicationController

  def status
    render json: {meta: System.info}
  end

  def reset
    System.reset
    Rails.logger.info "reset ok"

    # All good until here, send the reset email.
    SettingExecution::Personal.send_reset_email

    Thread.new do
      # Wait a bit to ensure 204 response from parent thread is properly sent.
      sleep 2
      # Disconnect from Wifi networks if configured
      SettingExecution::Network.reset unless Setting.find_by_slug('network_connectiontype').value.eql? 'lan'

      MirrOSApi::Application.load_tasks
      Rake::Task['db:recycle'].invoke

      Rails.env.development? ? System.restart_application : System.reboot
      Thread.exit
    end

    head :no_content

  rescue StandardError => e
    render json: {
      errors: [
        JSONAPI::Error.new(
          title: 'Error during reset attempt',
          detail: e.message,
          code: 500,
          status: :internal_server_error
        )
      ]
    }, status: 500
    # TODO: Remove installed extensions as well, since they're no longer registered in the database
  end

  def reboot
    System.reboot
  rescue StandardError => e
    render json: {
      errors: [
        JSONAPI::Error.new(
          title: 'Error during reboot attempt',
          detail: e.message,
          code: 500,
          status: :internal_server_error
        )
      ]
    }, status: 500
  end

  def run_setup
    user_time = params[:reference_time]
    System.change_system_time(user_time)
    connection = Setting.find_by_slug('network_connectiontype').value

    Rails.configuration.configured_at_boot = true
    # FIXME: This is a temporary workaround to differentiate between
    # initial setup before first connection attempt and subsequent network problems.
    # Remove once https://gitlab.com/glancr/mirros_api/issues/87 lands

    # TODO: clean this up
    if connection == 'wlan'
      begin
        result = SettingExecution::Network.connect
        success = true
      rescue ArgumentError => e
        result = e.message
        success = false
      end
    else # Using LAN, no further setup required
      result = 'Using LAN connection'
      success = true
    end

    # Test online status
    retries = 0
    until retries > 5 || System.online?
      sleep 5
      retries += 1
    end

    if success && System.online?
      SettingExecution::Personal.send_setup_email
      System.toggle_timesyncd_ntp(true)

      create_default_instances
    else
      message = "Setup failed!\n"
      message << "Could not connect to WiFi, reason: #{result}\n" unless success
      message << 'Could not connect to the internet'
      Rails.logger.error message
    end

    render json: {success: success, result: result}
  end

  # TODO: Respond with appropriate status codes in addition to success
  def setting_execution
    executor = "SettingExecution::#{params[:category].capitalize}".safe_constantize
    if executor.respond_to?(params[:command])
      begin
        result = executor.send(params[:command])
        success = true
      rescue StandardError => e
        result = e.message
        success = false
      end
    else
      result = "#{params[:action]} is not a valid action for "\
               "#{params[:category]} settings. Valid actions are: "\
               "#{executor.methods}"
      success = false
    end
    render json: {success: success, result: result}
  end

  # @return [JSON] JSON:API formatted list of all available extensions for the given extension type
  def fetch_extensions
    # FIXME: Use API_HOST as well once migration is done.
    render json: HTTParty.get(
      "http://gems.marco-roth.ch/list/#{params[:type]}",
      timeout: 5
    )
  rescue SocketError, Net::OpenTimeout => e
    head :gateway_timeout
    Rails.logger.error e.message
  end

  # Checks if a logfile with the given name exists in the Rails log directory
  # and returns it.
  # @return [FileBody] Content of the requested log file
  def fetch_logfile
    logfile = "#{Rails.root}/log/#{params[:logfile]}.log"
    return head :not_found unless Pathname.new(logfile).exist?

    send_file(logfile)
  end

  def generate_system_report
    render json: DebugReport.installed_extensions.merge(DebugReport.active_instances)
  end

  def send_debug_report
    report = DebugReport.new(params[:title], params[:description], params[:email])
    res = report.send
    head res.code
  rescue StandardError => e
    render json: {
      errors: [
        JSONAPI::Error.new(
          title: 'Error while sending debug report',
          detail: e.message,
          code: 500,
          status: :internal_server_error
        )
      ]
    }, status: 500
  end

  private

  def create_default_instances
    locale = Setting.find_by_slug('system_language').value.to_sym
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

      InstanceAssociation.create(
        configuration: { "chosen": ['https://glancr.de/mirros-welcome.xml'] },
        group: Group.find_by_slug('newsfeed'),
        widget_instance: WidgetInstance.find_by_widget_id('ticker'),
        source_instance: SourceInstance.find_by_source_id('rss_feeds')
      )
    end
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
    # Set default in case an unknown locale was passed
    fragments = { url: 'en.uk', title: 'UK Holidays' } if fragments.value? nil
    holiday_calendar_hash(fragments)
  end

  def holiday_calendar_hash(fragments)
    {
      url: "https://calendar.google.com/calendar/ical/#{fragments[:url]}%23holiday%40group.v.calendar.google.com/public/basic.ics",
      title: "#{fragments[:title]} (Google)"
    }
  end
end
