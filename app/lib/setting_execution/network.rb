module SettingExecution

  # Apply network-related settings.
  class Network

    # TODO: Support other authentication methods as well
    def self.connect
      ssid = Setting.find_by_slug('network_ssid').value
      password = Setting.find_by_slug('network_password').value
      raise ArgumentError, 'SSID and password must be set' unless ssid.present? && password.present?

      success = os_subclass.connect(ssid, password)
      # TODO: Errors should be raised for API clients

      Rails.logger.error "Error joining WiFi with SSID #{ssid}" unless success
      success
    end

    def self.list
      available_networks = os_subclass.list
      Rails.logger.error 'Could not retrieve WiFi list' if available_networks.empty?
      available_networks
    end

    def self.open_ap
      success = os_subclass.open_ap
      Rails.logger.error 'Could not open GlancrAP' unless success
      success
    end

    def self.ap_active?
      os_subclass.ap_active?
    end

    def self.close_ap
      success = os_subclass.close_ap
      Rails.logger.error 'Could not close GlancrAP' unless success
      success
    end

    def self.os_subclass
      if OS.linux?
        NetworkLinux
      elsif OS.mac?
        NetworkMac
      else
        Rails.logger.error "Unsupported OS running on #{RUBY_PLATFORM}"
        raise NotImplementedError
      end
    end

    private_class_method :os_subclass

  end
end
