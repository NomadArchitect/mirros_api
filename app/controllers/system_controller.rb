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

      ActiveRecord::Base.transaction do
        calendar_widget = WidgetInstance.find_by_widget_id('calendar_event_list')
        calendar_source = SourceInstance.find_by_source_id('ical')
        InstanceAssociation.create(
          configuration: {"chosen": ["e4ffacba5591440a14a08eac7aade57c603e17c0_0"]},
          group: Group.find_by_slug('calendar'),
          widget_instance: calendar_widget,
          source_instance: calendar_source
        )

        newsfeed_widget = WidgetInstance.find_by_widget_id('ticker')
        newsfeed_source = SourceInstance.find_by_source_id('rss_feeds')
        InstanceAssociation.create(
          configuration: {"chosen": ["https://glancr.de/mirros-welcome.xml"]},
          group: Group.find_by_slug('newsfeed'),
          widget_instance: newsfeed_widget,
          source_instance: newsfeed_source
        )
      end
    else
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
      rescue ArgumentError,
        Terrapin::ExitStatusError,
        SocketError,
        Net::HTTPBadResponse => e
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
    render json: jsonapi_error('Error while sending debug report', e.message), status: 500
  end
end
