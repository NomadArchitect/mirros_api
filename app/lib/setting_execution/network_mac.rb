module SettingExecution

  # Apply network-related settings.
  class NetworkMac < Network

    # TODO: Support other authentication methods as well
    def self.join(ssid, password)
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
      # TODO
      raise NotImplementedError
    end

  end
end
