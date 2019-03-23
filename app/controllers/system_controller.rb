class SystemController < ApplicationController

  def status
    render json: {meta: System.info}
  end

  def reset
    System.reset
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
    head :no_content
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
    connection = Setting.find_by_slug('network_connectiontype').value
    SettingExecution::Network.close_ap
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

      create_default_instances
    else
      message = "Setup failed!\n"
      message << "Could not connect to WiFi, reason: #{result}\n" unless success
      message << 'Could not connect to the internet'
      Rails.logger.error message
      SettingExecution::Network.open_ap
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

      InstanceAssociation.create(
        configuration: {
          "chosen": ['e4ffacba5591440a14a08eac7aade57c603e17c0_0']
        },
        group: Group.find_by_slug('calendar'),
        widget_instance: WidgetInstance.find_by_widget_id('calendar_event_list'),
        source_instance: calendar_source
      )

      InstanceAssociation.create(
        configuration: {"chosen": ["https://glancr.de/mirros-welcome.xml"]},
        group: Group.find_by_slug('newsfeed'),
        widget_instance: WidgetInstance.find_by_widget_id('ticker'),
        source_instance: SourceInstance.find_by_source_id('rss_feeds')
      )
    end
  end

  def default_holiday_calendar(locale)
    {
      enGb: {
        url: 'https://calendar.google.com/calendar/ical/en.uk%23holiday%40group.v.calendar.google.com/public/basic.ics',
        title: 'UK Holidays (Google)'
      },
      deDe: {
        url: 'https://calendar.google.com/calendar/ical/de.german%23holiday%40group.v.calendar.google.com/public/basic.ics',
        title: 'Deutsche Feiertage (Google)'
      },
      frFr: {
        url: 'https://calendar.google.com/calendar/ical/fr.french%23holiday%40group.v.calendar.google.com/public/basic.ics',
        title: 'vacances en France (Google)'
      },
      esEs: {
        url: 'https://calendar.google.com/calendar/ical/es.spain%23holiday%40group.v.calendar.google.com/public/basic.ics',
        title: 'Vacaciones en España (Google)'
      },
      plPl: {
        url: 'https://calendar.google.com/calendar/ical/pl.polish%23holiday%40group.v.calendar.google.com/public/basic.ics',
        title: 'Polskie święta (Google)'
      },
      koKr: {
        url: 'https://calendar.google.com/calendar/ical/ko.south_korea%23holiday%40group.v.calendar.google.com/public/basic.ics',
        title: '한국의 휴일 (Google)'
      }
    }[locale]
  end
end
