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

    def self.os_subclass
      if OS.linux?
        NetworkLinux
      elsif OS.mac?
        NetworkMac
        # TODO: Maybe implement Windows someday.
      end
    end

    private_class_method :os_subclass

  end
end
