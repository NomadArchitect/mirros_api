module SettingExecution

  # Apply network-related settings.
  class NetworkLinux < Network

    # TODO: Support other authentication methods as well
    def self.connect(ssid, password)
      line = connect_command_for_distro
      line.run(ssid: ssid, password: password)
    end

    def self.list
      line = list_command_for_distro
      line.run
    end

    def self.open_ap
      line = Terrapin::CommandLine.new('nmcli', 'c add type wifi ')
    end

    def self.connect_command_for_distro
      distro = System.determine_linux_distro
      {
        'Ubuntu': Terrapin::CommandLine.new('nmcli', 'd wifi connect :ssid password :password'),
        'Raspbian': Terrapin::CommandLine.new('wpa_passphrase', ':ssid :password | sudo tee -a /etc/wpa_supplicant/wpa_supplicant.conf > /dev/null && sudo wpa_cli -i wlan0 reconfigure')
      }[distro]
    end
    private_class_method :connect_command_for_distro

    def self.list_command_for_distro
      distro = System.determine_linux_distro
      {
        'Ubuntu': Terrapin::CommandLine.new('nmcli -t --fields SSID d wifi list'),
        'Raspbian': Terrapin::CommandLine.new('iwlist wlan0 scan | grep ESSID | cut -d "\"" -f 2')
      }[distro]
    end
    private_class_method :list_command_for_distro

  end
end
