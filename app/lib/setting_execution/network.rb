# frozen_string_literal: true

module SettingExecution
  # Apply network-related settings. StandardError rescues are intentional to
  # decouple from platform-specific implementation details.
  class Network
    # TODO: Support other authentication methods as well
    def self.connect
      StateCache.s.connection_attempt = true
      ::System.push_status_update
      ssid = Setting.find_by(slug: :network_ssid).value
      password = Setting.find_by(slug: :network_password).value
      unless ssid.present? && password.present?
        raise ArgumentError, 'SSID and password must be set'
      end

      close_ap
      # disable_lan
      os_subclass.connect(ssid, password)
    rescue StandardError => e
      Rails.logger.error "Error joining WiFi: #{e.message}"
      open_ap
      raise e
    ensure
      StateCache.s.connection_attempt = false
      ::System.check_network_status
      ActionCable.server.broadcast 'status', payload: ::System.info
    end

    def self.enable_lan
      toggle_lan('on')
      os_subclass.reset
    end

    def self.disable_lan
      toggle_lan('off')
    end

    def self.reset
      os_subclass.reset
    end

    def self.list
      available_networks = os_subclass.list
      if available_networks.empty?
        Rails.logger.error 'Could not retrieve WiFi list'
      end
      available_networks
    end

    def self.wifi_signal_status
      os_subclass.wifi_signal_status
    end

    def self.open_ap
      os_subclass.open_ap
      true
    rescue StandardError => e
      Rails.logger.error "Could not open access point, reason: #{e.message}"
      false
    end

    def self.ap_active?
      os_subclass.ap_active?
    rescue StandardError => e
      Rails.logger.error "Could not determine access point status, reason: #{e.message}"
      false
    end

    def self.close_ap
      os_subclass.close_ap
      true
    rescue StandardError => e
      Rails.logger.error "Could not close access point, reason: #{e.message}"
      false
    end

    def self.remove_predefined_connections
      os_subclass.remove_predefined_connections
      NmNetwork.where(connection_id: %w[glancrlan glancrsetup]).destroy_all
    rescue StandardError => e
      Rails.logger.error "Could not delete predefined connections: #{e.message}"
    end

    def self.remove_stale_connections
      os_subclass.remove_stale_connections
    rescue StandardError => e
      Rails.logger.error "Could not delete stale connections: #{e.message}"
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
      unless %w[on off].include? state
        raise ArgumentError, 'valid args are "on" or "off"'
      end

      begin
        success = os_subclass.toggle_lan(state)
      rescue StandardError => e
        Rails.logger.error "Could not toggle LAN connection to #{state}, reason: #{e.message}"
        success = false
      end
      success
    end

    private_class_method :toggle_lan
  end
end
