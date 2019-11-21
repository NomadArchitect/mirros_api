# frozen-string-literal: true

require 'os'

module SettingExecution
  # Provides methods to apply settings in the display namespace.
  class Display
    def self.orientation(degrees)
      config_file = Rails.root.join('public', 'config.txt')
      begin
        configuration = File.read(config_file)
        File.write(config_file,
                   configuration.gsub(/rotate_hdmi_display=[0-4]/,
                                      "rotate_hdmi_display=#{degrees}"))
        true
      rescue Errno::ENOENT => e
        Rails.logger.error "Failed to apply setting #{__method__} with parameter #{degrees}, cause: #{e}"
        false
      end
    end
  end
end
