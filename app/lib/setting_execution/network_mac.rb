# frozen_string_literal: true

module SettingExecution
  # Apply network-related settings.
  class NetworkMac < Network
    # TODO: Support other authentication methods as well
    def self.connect_to_wifi(ssid, password)
      line = Terrapin::CommandLine.new('networksetup', '-setairportnetwork :iface :ssid :password')
      begin
        success = line.run(iface: ::System.current_interface,
                           ssid: ssid,
                           password: password)
      rescue Terrapin::ExitStatusError => e
        Rails.logger.error "Error setting SSID to #{ssid}, cause: #{e.message}"
        success = false
      end
      success
    end

    def self.list
      # TODO. Airport Utility at /System/Library/PrivateFrameworks/Apple80211.framework/
      # Versions/Current/Resources/airport has a legacy switch `-s`
      if prod_server
        raise NotImplementedError, 'WiFi listing only implemented for Linux hosts'
      end

      [
        { ssid: 'this is not a real wifi', encryption: true, signal: 70 },
        { ssid: 'this is neither', encryption: false, signal: 50 }
      ]
    end

    def self.wifi_signal_status
      # Just get the first mock network.
      list.pop
    end

    def self.reset
      if prod_server
        raise NotImplementedError, 'Network reset only implemented for Linux hosts'
      end

      # TODO: Use /usr/sbin/networksetup to remove a preferred network.
      true
    end

    def self.open_ap
      if prod_server
        raise NotImplementedError, 'AP functionality only implemented for Linux hosts'
      end

      # TODO: Implement this if possible through CLI tools in macOS
      true
    end

    def self.ap_active?
      if prod_server
        raise NotImplementedError, 'AP functionality only implemented for Linux hosts'
      end

      # TODO: Implement this if possible through /usr/sbin/networksetup
      !StateCache.get :setup_complete
    end

    def self.close_ap
      if prod_server
        raise NotImplementedError, 'AP functionality only implemented for Linux hosts'
      end

      # TODO: Implement this if possible through CLI tools in macOS
      true
    end

    def self.prod_server
      Rails.env.production? && Rails.const_defined?('Server')
    end

    def self.remove_predefined_connections
      true
    end
  end
end
