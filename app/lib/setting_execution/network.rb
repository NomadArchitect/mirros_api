module SettingExecution

  # Apply network-related settings.
  class Network

    # TODO: Support other authentication methods as well
    def self.join
      ssid = Setting.find_by_slug('network_ssid').value
      password = Setting.find_by_slug('network_password').value

      success = os_subclass.join(ssid, password)
      Rails.logger.error "Error setting SSID to #{ssid}" unless success
      success
    end

    def self.list
      available_networks = os_subclass.list
      Rails.logger.error "Could not retrieve WiFi list" if available_networks.empty?
      available_networks
    end

    private_class_method def self.os_subclass
      if OS.linux?
        NetworkLinux
      elsif OS.mac?
        NetworkMac
      # TODO: Maybe implement Windows someday.
      end
    end

  end
end
