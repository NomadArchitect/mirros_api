# frozen_string_literal: true

module SettingExecution
  # Apply network-related settings. StandardError rescues are intentional to
  # decouple from platform-specific implementation details.
  class Network
    # TODO: Support other authentication methods as well
    def self.connect
      ssid = Setting.find_by(slug: :network_ssid).value
      password = Setting.find_by(slug: :network_password).value
      raise ArgumentError, 'SSID and password must be set' unless ssid.present? && password.present?

      close_ap

      conn_type = Setting.value_for(:network_connectiontype)
      case conn_type
      when 'wlan'
        os_subclass.connect_to_wifi(ssid, password)
      when 'lan'

      else
        raise ArgumentError, "invalid connection type #{conn_type}"
      end

      validate_connectivity

    rescue StandardError => e
      Rails.logger.error "Error joining WiFi: #{e.message}"
      open_ap
      raise e
    end

    def self.reset
      os_subclass.reset
    end

    # List available networks.
    def self.list
      os_subclass.list
    end
    end

    def self.wifi_signal_status
      os_subclass.wifi_signal_status
    end

    def self.schedule_ap(delay = '15m')
      begin
        Fugit::Duration.do_parse(delay)
      rescue ArgumentError => e
        raise "Unparseable delay #{delay}: #{e.message}"
      end

      Sidekiq.set_schedule OpenSetupWiFiJob.name, {
        in: delay,
        class: OpenSetupWiFiJob
      }
      Rails.logger.info 'Scheduled AP opening in 15m'
    end

    def self.cancel_ap_schedule
      Sidekiq.remove_schedule OpenSetupWiFiJob.name
      Rails.logger.info 'Unscheduled AP opening'
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
    rescue StandardError => e
      Rails.logger.error "Could not delete predefined connections: #{e.message}"
    end

    def self.remove_stale_connections
      os_subclass.remove_stale_connections
    rescue StandardError => e
      Rails.logger.error "Could not delete stale connections: #{e.message}"
    end

    def self.os_subclass
      if OS.linux? || OS.mac?
        NetworkLinux
      else
        Rails.logger.error "Unsupported OS running on #{RUBY_PLATFORM}"
        raise NotImplementedError, "Unsupported OS running on #{RUBY_PLATFORM}"
      end
    end

    private_class_method :os_subclass

    def self.validate_connectivity
      retries = 0
      until retries > 24 || (::System.online? || ::System.local_network_connectivity?)
        sleep 5
        retries += 1
      end

      raise StandardError, 'Could not connect to the internet within two minutes' if retries > 24
    end
  end
end
