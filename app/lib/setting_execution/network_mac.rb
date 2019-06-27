module SettingExecution

  # Apply network-related settings.
  class NetworkMac < Network

    # TODO: Support other authentication methods as well
    def self.connect(ssid, password)
      line = Terrapin::CommandLine.new("networksetup", "-setairportnetwork :iface :ssid :password")
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
      raise NotImplementedError, 'WiFi listing only implemented for Linux hosts' unless Rails.env.development?

      [
        { ssid: 'this is not a real wifi, just testing', signal: 70 },
        { ssid: 'this is neither', signal: 50 }
      ]
    end

    def self.check_signal(ssid)
      list.select { |wifi| wifi[:ssid].eql?(ssid) }.pop
    end

    def self.toggle_lan(_state)
      raise NotImplementedError, 'LAN toggle only implemented for Linux hosts' unless Rails.env.development?

      # TODO: Use /usr/sbin/networksetup to remove a preferred network.
      true
    end

    def self.reset
      raise NotImplementedError, 'Network reset only implemented for Linux hosts' unless Rails.env.development?

      # TODO: Use /usr/sbin/networksetup to remove a preferred network.
      true
    end

    def self.open_ap
      raise NotImplementedError, 'AP functionality only implemented for Linux hosts' unless Rails.env.development?

      # TODO: Implement this if possible through CLI tools in macOS
      true
    end

    def self.ap_active?
      raise NotImplementedError, 'AP functionality only implemented for Linux hosts' unless Rails.env.development?

      # TODO: Implement this if possible through /usr/sbin/networksetup
      !StateCache.s.setup_complete
    end

    def self.close_ap
      raise NotImplementedError, 'AP functionality only implemented for Linux hosts' unless Rails.env.development?

      # TODO: Implement this if possible through CLI tools in macOS
      true
    end
  end
end
