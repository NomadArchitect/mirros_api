# frozen_string_literal: true

# Data structure for debug reports.
class DebugReport
  UUID_REGEX = /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/.freeze

  # Builds a system report structure with various debugging information.
  # @return [Hash]
  def self.system_report
    report = {}
    report[:source_instances] = SourceInstance.all.map do |si|
      {
        id: si.id,
        source: si.source.name,
        connected_widget_instances: {
          total: si.widget_instances.count,
          list: si.widget_instances.map { |wi| { id: wi.id, name: wi.widget.name } }
        }

      }
    end
    report[:widget_instances] = WidgetInstance.all.map do |wi|
      info = {
        id: wi.id,
        widget: wi.widget.name
      }
      unless wi.group.nil?
        info[:connected_source_instances] = {
          total: wi.source_instances.count,
          list: wi.source_instances.map { |si| { id: si.id, name: si.source.name } }
        }
      end
      info
    end

    report[:additional_extensions] = {
      widgets: Rails.application.gems_in_extension_group(group: :widget, manually_installed: true),
      sources: Rails.application.gems_in_extension_group(group: :source, manually_installed: true)
    }
    begin
      report[:uploads] = Upload.all.map do |upload|
        {
          type: upload.type,
          content_type: upload.file.content_type,
          file_size_mb: (upload.file.byte_size.to_f / 1_048_576).ceil(2) # 1048576 = 2**20, convert from byte to megabyte.
        }
      end
    rescue StandardError => e
      Rails.logger.error __method__ + e.message
    end

    report
  end

  # @param [String] title The title of this report
  # @param [String] description A user-provided text description of the error(s).
  # @param [String] email Optional reply-to email address. Uses configured system email otherwise.
  def initialize(title, description, email = nil)
    @file_handles = []

    pictures_wi = Widget.find_by(name: 'pictures').widget_instances
    @body = {
      title: title,
      description: description,
      email: email.nil? ? Setting.value_for(:personal_email) : email,
      # Use yes/no to avoid type conversions of booleans during transit and support scripts.
      validProductKey: Setting.value_for(:personal_productkey).match?(UUID_REGEX) ? :yes : :no,
      debugging_info: "
        pi_model: #{ENV['SNAP'].nil? ? 'not in snap env' : pi_model}
        uptime_snapshot: #{ENV['SNAP'].nil? ? 'not in snap env' : uptime_snapshot}
        snap_version: #{SNAP_VERSION}
        network_manager_version: #{ENV['SNAP'].nil? ? 'not in snap env' : nm_version}
        service_status:\n#{ENV['SNAP'].nil? ? 'not in snap env' : service_status}
        connection type: #{Setting.value_for(:network_connectiontype)}
        language: #{Setting.value_for(:system_language)}
        timezone:
            configured: #{Setting.value_for(:system_timezone)}
            active for Rails: #{Time.zone.name}
        multi-board:
            active: #{Setting.value_for(:system_multipleboards)}
            rotation: #{Setting.value_for(:system_boardrotation)}
            interval: #{Setting.value_for(:system_boardrotationinterval)}
        IP Cam widget active (assuming an active stream): #{Widget.find_by(name: 'ip_cam').widget_instances.count.positive?}
        Pictures widget active: #{pictures_wi.count.positive?}
        Image Gallery – rotation / remote:
            #{pictures_wi.map(&:configuration)}
        widget instances: #{WidgetInstance.count}
        source instances: #{SourceInstance.count}
      "
    }
  end

  # Appends log files to the report and sends it to the glancr API server.
  # Separate method to include any errors during initialization in the logs.
  # @return [HTTParty::Response]
  def send_mail
    append_system_report
    append_rails_log_files
    unless ENV['SNAP_COMMON'].nil?
      append_nginx_log_files
      append_mysql_log_files
    end
    host = "https://#{System::API_HOST}/reports/new-one.php"
    res = HTTParty.post(host, body: @body)
    @file_handles.each(&:close)
    @file_handles.select { |handle| handle.unlink if handle.instance_of?(Tempfile) }

    res
  end

  private

  # Retrieves the Raspberry Pi model of this installation.
  # @return [String (frozen)]
  def pi_model
    Terrapin::CommandLine.new('cat', '/proc/cpuinfo | grep Model').run&.split(':').last.strip!
  rescue StandardError => e
    "Could not determine Pi model: #{e.message}"
  end

  # Retrieves a snapshot of the current system load via `uptime`.
  # @return [String (frozen)]
  def uptime_snapshot
    Terrapin::CommandLine.new('uptime').run.chomp
  rescue StandardError => e
    "Failed to run uptime: #{e.message}"
  end

  # Retrieves the current snap service status.
  # @return [String (frozen), nil]
  def service_status
    Terrapin::CommandLine.new(
      'snapctl',
      'services mirros-one'
    )
                         .run
                         .chomp
                         .each_line.map { |line| line.squish!.prepend('            ') }
                         .join("\n")
  rescue StandardError => e
    "Failed to run service command: #{e.message}"
  end

  # Retrieves the installed network-manager version.
  # @return [String (frozen)]
  def nm_version
    NetworkManager::Commands.instance.nm_version
  rescue StandardError => e
    "Failed to get NM version: #{e.message}"
  end

  # Appends nginx log files to the @body instance variable if available.
  # @return [nil]
  def append_nginx_log_files
    nginx_log_path = Pathname("#{ENV['SNAP_COMMON']}/nginx/log")
    return unless nginx_log_path.exist?

    Dir.each_child(nginx_log_path) do |log_file|
      log_path = Pathname("#{nginx_log_path}/#{log_file}")
      next unless log_path.extname.eql?('.log')

      file_ref = File.open(log_path)
      @body[log_file.slice(0..-5)] = file_ref
      @file_handles << file_ref
    end
  end

  # Appends all available rails log files to the @body instance variable.
  # @return [nil]
  def append_rails_log_files
    %w[production scheduler clients].each do |log_file|
      log_path = Pathname(Rails.root.join('log', "#{log_file}.log"))
      next unless log_path.exist?

      file_ref = File.open(log_path)
      @body[log_file] = file_ref
      @file_handles << file_ref
    end
  end

  # Appends mysql error log file to the @body instance variable.
  # @return [nil]
  def append_mysql_log_files
    mysql_log_path = Pathname("#{ENV['SNAP_COMMON']}/mysql/log/error.log")
    return unless mysql_log_path.exist?

    file_ref = File.open(mysql_log_path)
    @body['mysql_error_log'] = file_ref
    @file_handles << file_ref
  end

  # Appends the system report JSON file.
  # @return [nil]
  def append_system_report
    tmpfile = Tempfile.open %w[system_report .json]
    tmpfile.write JSON.pretty_generate(DebugReport.system_report)
    @body['system_report'] = tmpfile.open
    @file_handles << tmpfile
  end
end
