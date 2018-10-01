module SettingExecution

  # Apply network-related settings.
  class NetworkMac < Network

    # TODO: Support other authentication methods as well
    def self.connect(ssid, password)
      line = Terrapin::CommandLine.new("networksetup", "-setairportnetwork :iface :ssid :password")
      begin
        success = line.run(iface: System.current_interface,
                           ssid: ssid,
                           password: password)
      rescue Terrapin::ExitStatusError => e
        Rails.logger.error "Error setting SSID to #{ssid}, cause: #{e.message}"
      end
      success
    end

    def self.list
      # TODO. Airport Utility at /System/Library/PrivateFrameworks/Apple80211.framework/
      # Versions/Current/Resources/airport has a legacy switch `-s`
      raise NotImplementedError unless Rails.env.development?

      ['this is not a real wifi, just testing', 'this is neither']
    end

    def self.open_ap
      raise NotImplementedError unless Rails.env.development?

      # TODO: Implement this if possible through CLI tools in macOS
      true
    end

    def self.close_ap
      raise NotImplementedError unless Rails.env.development?

      # TODO: Implement this if possible through CLI tools in macOS
      true
    end
  end
end
