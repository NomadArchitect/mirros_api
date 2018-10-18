module SettingExecution

  # Apply network-related settings in Linux environments.
  #
  # Requires the packages network-manager (provides nmcli) and wireless-tools
  # (provides iwlist) to be installed and executable. The AP-related methods
  # assume that there is a valid nmcli connection named `glancrsetup`.
  class NetworkLinux < Network

    # TODO: Support other authentication methods as well
    def self.connect(ssid, password)
      # Clear existing connections so that we only have one connection with that name.
      remove_connection(ssid)

      line = Terrapin::CommandLine.new('nmcli', 'd wifi connect :ssid password :password')
      line.run(ssid: ssid, password: password)
    end

    def self.list
      # TODO: Terrapin::CommandLine.new('nmcli -t --fields SSID d wifi list')
      # would be prettier, but we require two interfaces to scan while in AP mode.
      # FIXME: This also assumes that the WiFi interface is named wlan0 (nmcli would manage that for us)
      line = Terrapin::CommandLine.new('iwlist',
                                       'wlan0 scan | grep ESSID | cut -d "\"" -f 2')
      line.run.split("\n")
    end

    def self.reset
      ssid = Setting.find_by_slug('network_ssid').value
      remove_connection(ssid) unless ssid.empty?
    end

    def self.open_ap
      dns_line = Terrapin::CommandLine.new('snapctl', 'start mirros-one.dns')
      result = dns_line.run

      wifi_line = Terrapin::CommandLine.new('nmcli', 'c up glancrsetup')
      result << "\n"
      result << wifi_line.run
      result
    end

    #
    # @return [Boolean] True if the AP connection is among the active nmcli connections.
    def self.ap_active?
      line = Terrapin::CommandLine.new('nmcli',
                                       '-f NAME c show --active | grep glancrsetup',
                                       expected_outcodes: [0, 1])
      line.run
      line.exit_status.zero?
    end

    def self.close_ap
      wifi_line = Terrapin::CommandLine.new('nmcli', 'c down glancrsetup')
      result = wifi_line.run

      dns_line = Terrapin::CommandLine.new('snapctl', 'stop mirros-one.dns')
      result << "\n"
      result << dns_line.run
      result
    end

    # Removes a named nmcli connection. Catch exit code 10 ("cannot delete unknown connection(s)").
    # @param [String] connection The connection name to remove.
    def self.remove_connection(connection)
      line = Terrapin::CommandLine.new('nmcli',
                                       'c delete :connection',
                                       expected_outcodes: [0, 10])
      line.run(connection: connection)
    end
    private_class_method :remove_connection

  end
end
