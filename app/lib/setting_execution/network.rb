module SettingExecution

  # Apply network-related settings.
  class Network

    # TODO: Support other authentication methods as well
    def self.connect
      StateCache.s.connection_attempt = true
      ssid = SettingsCache.s[:network_ssid]
      password = SettingsCache.s[:network_password]
      raise ArgumentError, 'SSID and password must be set' unless ssid.present? && password.present?

      SettingExecution::Network.close_ap
      disable_lan

      success = os_subclass.connect(ssid, password)
      # TODO: Errors should be raised for API clients
      #
      unless success
        Rails.logger.error "Error joining WiFi with SSID #{ssid}, reopening AP"
        SettingExecution::Network.open_ap
      end
      StateCache.s.connection_attempt = false
      success
    end

    def self.enable_lan
      toggle_lan('on')
    end

    def self.disable_lan
      toggle_lan('off')
    end

    def self.reset
      os_subclass.reset
      disable_lan
    end

    def self.list
      available_networks = os_subclass.list
      Rails.logger.error 'Could not retrieve WiFi list' if available_networks.empty?
      available_networks
    end

    def self.check_signal
      ssid = SettingsCache.s[:network_ssid]
      return if ssid.nil? || ssid.empty?

      os_subclass.check_signal(ssid)
    end

    def self.open_ap
      begin
        success = os_subclass.open_ap
      rescue Terrapin::ExitStatusError, Terrapin::CommandNotFoundError => e
        Rails.logger.error "Could not open access point, reason: #{e.message}"
        success = false
      end
      success
    end

    def self.ap_active?
      begin
        success = os_subclass.ap_active?
      rescue Terrapin::ExitStatusError, Terrapin::CommandNotFoundError => e
        Rails.logger.error "Could not determin access point status, reason: #{e.message}"
        success = false
      end
      success
    end

    def self.close_ap
      begin
        success = os_subclass.close_ap
      rescue Terrapin::ExitStatusError, Terrapin::CommandNotFoundError => e
        Rails.logger.error "Could not close access point, reason: #{e.message}"
        success = false
      end
      success
    end

    def self.os_subclass
      if OS.linux?
        NetworkLinux
      elsif OS.mac?
        NetworkMac
      else
        Rails.logger.error "Unsupported OS running on #{RUBY_PLATFORM}"
        raise NotImplementedError, "Unsupported OS running on #{RUBY_PLATFORM}"
      end
    end

    private_class_method :os_subclass

    def self.toggle_lan(state)
      raise ArgumentError, 'valid args are "on" or "off"' unless %w[on off].include? state

      begin
        success = os_subclass.toggle_lan(state)
      rescue Terrapin::CommandLineError => e
        Rails.logger.error "Could not toggle LAN connection to #{state}, reason: #{e.message}"
        success = false
      end
      success
    end

    private_class_method :toggle_lan

  end
end
