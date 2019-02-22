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

  def append_log_files
    log_files = %i[production scheduler]
    log_files.each do |log_file|
      path = "#{Rails.root}/log/#{log_file}.log"
      @body[log_file] = File.open(path, 'rb') if Pathname.new(path).exist?
    end
  end

end
