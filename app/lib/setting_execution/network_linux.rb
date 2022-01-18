# frozen_string_literal: true

module SettingExecution
  # Apply network-related settings in Linux environments.
  #
  # Requires the package wireless-tools to run iwlist in `list`.
  # The AP-related methods assume that there is a valid NetworkManager connection
  # named `glancrsetup`.
  class NetworkLinux < Network

    # TODO: Support other authentication methods as well
    # @param [String] ssid
    # @param [String] password
    def self.connect_to_wifi(ssid, password)
      # Clear existing connections so that we only have one connection with that name.
      NetworkManager::Bus.new.activate_new_wifi_connection(ssid, password)
    end

    def self.list
      # TODO: Obtaining visible Access Points via NetworkManager Wifi device interface
      # would be prettier, but would require two interfaces to scan while in AP mode.
      line = Terrapin::CommandLine.new('iwlist',
                                       ':iface scan | egrep "Quality|Encryption key|ESSID"')
      results = line.run(iface: NetworkManager::Bus.new.wifi_interface)&.split("\"\n")
      results&.map do |result|
        signal, encryption, ssid = result.split("\n")
        {
          ssid: ssid.match(/".*$/).to_s.delete('"'),
          encryption: encryption.include?('on'),
          signal: normalize_signal_strength(signal)
        }
      end
    end

    # iwlist prints signal strength on a scale to 70; normalize to 0-100 percent.
    # @param [String] signal string containing the signal strength as a two-digit integer
    def self.normalize_signal_strength(signal)
      (Integer(signal.match(/\d{2}/).to_s).fdiv(70).floor(2) * 100).to_i
    end

    private_class_method :normalize_signal_strength

    def self.wifi_signal_status
      NetworkManager::Bus.new.wifi_status
    rescue StandardError => e
      Rails.logger.error "#{__method__}: #{e.message}"
      nil
    end

    def self.reset
      NetworkManager::Bus.new.delete_connection('glancrsetup')
      NetworkManager::Bus.new.delete_connection('glancrlan')
      NetworkManager::Bus.new.add_predefined_connections
    end

    def self.open_ap
      dns_line = Terrapin::CommandLine.new('snapctl', 'start mirros-one.dns')
      dns_line.run # throws on error
      NetworkManager::Bus.new.activate_connection('glancrsetup')
    rescue StandardError => e
      Rails.logger.warn "#{__method__} #{e.message}"
    end

    #
    # @return [Boolean] True if the AP connection is active and the DNS service is running.
    def self.ap_active?
      dns_line = Terrapin::CommandLine.new('snapctl', "services mirros-one.dns | awk 'FNR == 2 {print $3}'")
      result = dns_line.run&.chomp!
      NetworkManager::Bus.new.connection_active?('glancrsetup') && result.eql?('active')
    end

    # @return [TrueClass] True if the connection was deactivated, false otherwise.
    def self.close_ap
      dns_line = Terrapin::CommandLine.new('snapctl', 'stop mirros-one.dns')
      dns_line.run
      NetworkManager::Bus.new.deactivate_connection('glancrsetup')
    rescue StandardError => e
      Rails.logger.warn "#{__method__} #{e.message}"
    end
  end
end
