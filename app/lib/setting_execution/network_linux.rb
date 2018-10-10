module SettingExecution

  # Apply network-related settings in Linux environments.
  #
  # Requires the packages network-manager (provides nmcli) and wireless-tools
  # (provides iwlist) to be installed and executable. The AP-related methods
  # assume that there is a valid nmcli connection named `glancrsetup`.
  class NetworkLinux < Network

    # TODO: Support other authentication methods as well
    def self.connect(ssid, password)
      line = Terrapin::CommandLine.new('nmcli', 'd wifi connect :ssid password :password')
      line.run(ssid: ssid, password: password)
    end

    def self.list
      # TODO: Terrapin::CommandLine.new('nmcli -t --fields SSID d wifi list')
      # would be prettier, but we require two interfaces to scan while in AP mode.
      line = Terrapin::CommandLine.new('iwlist', 'wlan0 scan | grep ESSID | cut -d "\"" -f 2')
      line.run
    end

    def self.open_ap
      dns_line = Terrapin::CommandLine.new('snapctl', 'start mirros-one.dns')
      result = dns_line.run

      wifi_line = Terrapin::CommandLine.new('nmcli', 'c up glancrsetup')
      result << "\n"
      result << wifi_line.run
      result
    end

    def self.ap_active?
      line = Terrapin::CommandLine.new('nmcli', 'c show --active | grep -i glancrsetup')
      line.run.empty?
    end

    def self.close_ap
      wifi_line = Terrapin::CommandLine.new('nmcli', 'c down glancrsetup')
      result = wifi_line.run

      dns_line = Terrapin::CommandLine.new('snapctl', 'stop mirros-one.dns')
      result << "\n"
      result << dns_line.run
      result
    end
  end
end
