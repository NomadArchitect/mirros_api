# frozen_string_literal: true

module SettingExecution
  # Apply network-related settings in Linux environments.
  #
  # Requires the package wireless-tools to run iwlist in `list`.
  # The AP-related methods assume that there is a valid NetworkManager connection
  # named `glancrsetup`.
  class NetworkLinux < Network
    include NetworkManager

    # TODO: Support other authentication methods as well
    # @param [String] ssid
    # @param [String] password
    def self.connect(ssid, password)
      # Clear existing connections so that we only have one connection with that name.
      remove_stale_connections
      Commands.instance.activate_new_wifi_connection(
        ssid,
        password
      )
    end

    def self.list
      # TODO: Obtaining visible Access Points via NetworkManager Wifi device interface
      # would be prettier, but would require two interfaces to scan while in AP mode.
      line = Terrapin::CommandLine.new('iwlist',
                                       ':iface scan | egrep "Quality|Encryption key|ESSID"')
      results = line.run(iface: Commands.instance.wifi_interface)&.split("\"\n")
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
      Commands.instance.wifi_status
    rescue StandardError => e
      Rails.logger.error "#{__method__}: #{e.message}"
      nil
    end

    def self.toggle_lan(state)
      case state
      when 'on'
        Commands.instance.activate_connection('glancrlan')
      when 'off'
        Commands.instance.deactivate_connection('glancrlan')
      else
        raise ArgumentError,
              "Could not toggle glancrlan to invalid state: #{state}"
      end
    end

    def self.reset
      remove_stale_connections
    end

    # @return [NmNetwork] the updated glancrsetup network model.
    def self.open_ap
      dns_line = Terrapin::CommandLine.new('snapctl', 'start mirros-one.dns')
      dns_line.run # throws on error
      Commands.instance.activate_connection('glancrsetup')
    end

    #
    # @return [Boolean] True if the AP connection is present in NetworkManager's active connection list.
    def self.ap_active?
      # TODO: This should also check whether the DNS service is running
      Commands.instance.connection_active? 'glancrsetup'
    end

    # @return [NmNetwork] the updated glancrsetup network model.
    def self.close_ap
      dns_line = Terrapin::CommandLine.new('snapctl', 'stop mirros-one.dns')
      dns_line.run
      Commands.instance.deactivate_connection('glancrsetup')
    end

    # Removes all NetworkManager WiFi connections.
    def self.remove_stale_connections
      Commands.instance.delete_all_wifi_connections
    end

    def self.remove_predefined_connections
      Commands.instance.delete_connection(connection_id: 'glancrsetup')
      Commands.instance.delete_connection(connection_id: 'glancrlan')
    end
  end
end
