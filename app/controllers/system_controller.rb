class SystemController < ApplicationController

  def status
    render json: { meta: System.info }
  end

  def reset
    System.reset
    head :no_content
    # TODO: Remove installed extensions as well, since they're no longer registered in the database
  end

  def reboot
    head :ok
    Thread.new do
      System.reboot
    end
  end

  def run_setup
    connection = Setting.find_by_slug('network_connectiontype').value
    SettingExecution::Network.close_ap

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

    # TODO: Evaluate: Since nmcli should not return before the connection is
    # established, we should not need a retry loop here.
    if success && System.online?
      SettingExecution::Personal.send_setup_email
    else
      SettingExecution::Network.open_ap
    end

    render json: { success: success, result: result }
  end

  # TODO: Respond with appropriate status codes in addition to success
  def setting_execution
    executor = "SettingExecution::#{params[:category].capitalize}".safe_constantize
    if executor.respond_to?(params[:command])
      begin
        result = executor.send(params[:command])
        success = true
      rescue ArgumentError,
             NotImplementedError,
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
  rescue Net::OpenTimeout => e
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
  end

end
