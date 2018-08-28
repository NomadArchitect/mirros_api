module SettingExecution

  # Apply network-related settings.
  class Network

    # TODO: Support other authentication methods as well
    def self.join(ssid, password)
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
      end
    end

  end
end
