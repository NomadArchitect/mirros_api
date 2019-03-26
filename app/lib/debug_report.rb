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
      wi_outside_grid_boundaries: widget_instances.select {|wi| wi.position['y'] + wi.position['height'] > 21},
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
      email: email.nil? ? Setting.find_by_slug('personal_email').value : email
    }
  end

  def send
    append_log_files
    host = "https://#{System::API_HOST}/reports/new-one.php"
    HTTParty.post(host, body: @body)
  end

  private

  # Appends Rails and nginx log files to the @body instance variable.
  # @return [nil]
  def append_log_files
    # Log errors before the log is appended
    if ENV['SNAP_COMMON'].nil?
      Rails.logger.error '[DebugReport] $SNAP_COMMON not set, skipping nginx log files'
    else
      nginx_log_path = Pathname("#{ENV['SNAP_COMMON']}/nginx/log")
      if nginx_log_path.exist?
        Dir.each_child(nginx_log_path) do |log_file|
          path = "#{ENV['SNAP_COMMON']}/nginx/log/#{log_file}"
          @body[log_file] = File.open(path, 'rb') if Pathname.new(path).exist?
        end
      end
    end

    rails_logs = %i[production scheduler]
    rails_logs.each do |log_file|
      path = "#{Rails.root}/log/#{log_file}.log"
      @body[log_file] = File.open(path, 'rb') if Pathname.new(path).exist?
    end
  end

end
