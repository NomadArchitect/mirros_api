# frozen_string_literal: true

# Data structure for debug reports.
class DebugReport
  # @return [Hash] Installed extensions by type, each an array of name and
  # version.
  def self.installed_extensions
    {
      widgets: Widget.all.pluck(:name, :version),
      sources: Source.all.pluck(:name, :version),
    }
  end

  # @return [Hash] Metrics on currently active widget/source instances.
  def self.active_instances
    widget_instances = WidgetInstance.all
    {
      wi_count: widget_instances.count,
      wi_outside_grid_boundaries: widget_instances.select { |wi| wi.position['y'] + wi.position['height'] > 21 },
      si_count: SourceInstance.all.count
    }
  end

  # @param [String] title
  # @param [String] description
  # @param [String] email
  def initialize(title, description, email = nil)
    @body = {
      title: title,
      description: description,
      email: email.nil? ? SettingsCache.s[:personal_email] : email
    }
  end

  def send
    @file_handles = []
    append_nginx_log_files unless ENV['SNAP_COMMON'].nil?
    append_rails_log_files
    append_debugging_info

    host = "https://#{System::API_HOST}/reports/new-one.php"
    res = HTTParty.post(host, body: @body)
    @file_handles.each(&:close)

    res
  end

  private

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

  def append_rails_log_files
    %w[production scheduler].each do |log_file|
      log_path = Pathname("#{Rails.root}/log/#{log_file}.log")
      next unless log_path.exist?

      file_ref = File.open(log_path)
      @body[log_file] = file_ref
      @file_handles << file_ref
    end
  end

  def append_debugging_info
    @body['debugging_info'] = JSON.pretty_generate(
      extensions: DebugReport.installed_extensions,
      instances: DebugReport.active_instances
    )
  end

end
