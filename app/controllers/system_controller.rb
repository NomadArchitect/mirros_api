# frozen_string_literal: true

class SystemController < ApplicationController
  def status
    render json: { meta: System.status }
  rescue StandardError => e
    render json: jsonapi_error('Error during status fetch', e.message, 500),
           status: :internal_server_error
  end

  def reset
    StateCache.put :resetting, true

    # All good until here, send the reset email.
    SettingExecution::Personal.send_reset_email

    Thread.new do
      # Wait a bit to ensure 204 response from parent thread is properly sent.
      sleep 2
      # Disconnect from Wifi networks if configured
      SettingExecution::Network.reset

      MirrOSApi::Application.load_tasks
      Rake::Task['db:recycle'].invoke

      Rails.env.development? ? System.restart_application : System.reboot
      Thread.exit
    end

    head :no_content
  rescue StandardError => e
    StateCache.put :resetting, false
    Rails.logger.error e.message
    render json: jsonapi_error('Error during reset', e.message, 500),
           status: :internal_server_error
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

    StateCache.put :running_setup_tasks, true

    # Schedule before connecting to network, so the job is scheduled before a potential refresh.
    CreateDefaultBoardJob.set(wait: 5.seconds).perform_later if options[:create_defaults]
    ConnectToNetworkJob.perform_now unless Setting.value_for(:system_connectiontype).eql?(:lan)
    sleep 2
    SendWelcomeMailJob.perform_now unless System.local_network_mode_enabled?

    render json: { meta: System.status }, status: :accepted
  rescue StandardError => e
    Rails.logger.error "#{__method__} #{e.message}"
    # e.g. wrong WiFi password -> no error during connection, but not online
    SettingExecution::Network.open_ap
    render json: jsonapi_error('Error during setup', e.message, 500),
           status: :internal_server_error
  ensure
    System.daily_reboot
  end

  # TODO: Respond with appropriate status codes in addition to success
  def setting_execution
    executor = "SettingExecution::#{params[:category].capitalize}".safe_constantize
    if executor.respond_to?(params[:command].to_s)
      begin
        result = if executor.method(params[:command].to_s).arity.positive?
                   executor.send(params[:command], *params)
                 else
                   executor.send(params[:command].to_s)
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
    return head :no_content unless System.running_in_snap?

    # create-backup script is included in mirros-one-snap repository
    line = Terrapin::CommandLine.new('create-backup')
    backup_location = Pathname.new("#{ENV['SNAP_DATA']}/#{line.run.chomp}")
    send_file(backup_location) if backup_location.exist?
  end

  def restore_settings
    return unless System.running_in_snap?

    StateCache.put :resetting, true
    SettingExecution::Network.close_ap # Would also be closed by run_setup, but we don't want it open that long

    # TODO: Create backup of current state to roll back if necessary
    backup_file = params[:backup_file]
    FileUtils.mv backup_file.tempfile, "#{ENV['SNAP_DATA']}/#{backup_file.original_filename}"
    # restore-backup script is included in mirros-one-snap repository
    # FIXME: Ignore return code 1 until proper rollbacks are implemented.
    # In installations with SNAP_VERSION < 1.8.0, my.cnf didn't contain a password. Calling mysql with -p triggers a
    # warning which Terrapin interprets as a fatal error.
    line = Terrapin::CommandLine.new('restore-backup', ':backup_file')
    line.run(backup_file: "#{ENV['SNAP_DATA']}/#{backup_file.original_filename}")

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
