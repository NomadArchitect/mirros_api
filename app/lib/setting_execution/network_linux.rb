module SettingExecution

  # Apply network-related settings.
  class NetworkLinux < Network

    # TODO: Support other authentication methods as well
    def self.join_network(ssid, password)
      line = join_command_for_distro
      line.command(ssid: ssid, password: password)
      line.run
    end

    def self.list
      line = list_command_for_distro
      line.run
    end

    def self.open_ap
      line = Terrapin::CommandLine.new('nmcli', 'c add type wifi ')
    end

    def self.join_command_for_distro(ssid, password)
      distro = System.determine_linux_distro
      {
        'Ubuntu': Terrapin::CommandLine.new('nmcli', 'd wifi connect :ssid password :password'),
        'Raspbian': Terrapin::CommandLine.new('wpa_passphrase', ':ssid :password | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null && sudo wpa_cli -i wlan0 reconfigure')
      }[distro]
    end

    def self.list_command_for_distro
      distro = System.determine_linux_distro
      {
        'Ubuntu': Terrapin::CommandLine.new('nmcli -t d wifi list'),
        'Raspbian': Terrapin::CommandLine.new('iwlist wlan0 scan | grep ESSID | cut -d "\"" -f 2')
      }[distro]
    end

  end
end
