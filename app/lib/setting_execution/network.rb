module SettingExecution

  # Apply network-related settings.
  class Network

    # TODO: Support other authentication methods as well
    def self.connect
      StateCache.s.connection_attempt = true
      SettingExecution::Network.close_ap
      ssid = Setting.find_by_slug('network_ssid').value
      password = Setting.find_by_slug('network_password').value
      raise ArgumentError, 'SSID and password must be set' unless ssid.present? && password.present?

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

    def self.reset
      os_subclass.reset
    end

    def self.list
      available_networks = os_subclass.list
      Rails.logger.error 'Could not retrieve WiFi list' if available_networks.empty?
      available_networks
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

  end
end
