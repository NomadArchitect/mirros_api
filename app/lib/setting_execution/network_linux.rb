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

    # Lists WiFi networks visible to the primary WiFi device.
    # Uses iwlist as a fallback since NetworkManager cannot properly scan when it is connected
    # to an access point or our setup AP is up. Curiously, after iwlist has scanned, NetworkManager
    # shows all available networks again.
    # @return [Array<Hash{Symbol=>String,Integer,true,false}>]
    def self.list
      results = NetworkManager::Bus.new.list_wifi_networks
      if results.blank?
        results = wifi_networks_via_iwlist
        Rails.logger.warn "#{__method__}: using iwlist for wifi listing"
      end
      # Sort by signal strength and only keep the strongest signal for each SSID.
      results.sort! { |network_a, network_b| network_a[:signal] <=> network_b[:signal] }
             .reverse!
             .uniq! { |network| network[:ssid] }

      results
    end

    # Normalize iwlist signal quality scale 0-70 to match NetworkManager's 0-100 (percent).
    # @see https://superuser.com/a/1360447
    # @param [String] signal quality output line from iwlist which contains a two-digit integer
    def self.normalize_signal_strength(signal)
      (Integer(signal.match(/\d{2}/).to_s).fdiv(70).floor(2) * 100).to_i
    end

    private_class_method :normalize_signal_strength

    # Requests the WiFi device to re-scan for available networks via NetworkManager.
    # @return [Hash{Symbol=>Integer}] `last_scan` contains the last scan timestamp in CLOCK_BOOTTIME before the request.
    def self.request_scan
      NetworkManager::Bus.new.request_scan
    end

    # Retrieves the timestamp of the last scan for WiFi networks from NetworkManager.
    # @return [Hash{Symbol=>Integer}] `last_scan` contains the last scan timestamp in CLOCK_BOOTTIME before the request.
    def self.last_scan
      NetworkManager::Bus.new.last_scan
    end

    # Retrieves WiFi details like signal strength and SSID for the currently active WiFi connection.
    def self.wifi_signal_status
      NetworkManager::Bus.new.wifi_status
    rescue StandardError => e
      Rails.logger.error "#{__method__}: #{e.message}"
      nil
    end

    # Resets all network connections to the factory default.
    def self.reset
      bus = NetworkManager::Bus.new
      bus.delete_all_connections
      bus.add_predefined_connections
    end

    # Starts the setup access point connection in NetworkManager.
    def self.open_ap
      dns_line = Terrapin::CommandLine.new('snapctl', 'start mirros-one.dns')
      dns_line.run # throws on error
      NetworkManager::Bus.new.activate_connection('glancrsetup')
    rescue StandardError => e
      Rails.logger.warn "#{__method__} #{e.message}"
    end

    # Checks if the setup access point is currently active.
    # @return [Boolean] True if the AP connection is active and the DNS service is running.
    def self.ap_active?
      dns_line = Terrapin::CommandLine.new('snapctl', "services mirros-one.dns | awk 'FNR == 2 {print $3}'")
      result = dns_line.run&.chomp!
      result.eql?('active') && NetworkManager::Bus.new.connection_active?('glancrsetup')
    end

    # @return [TrueClass] True if the connection was deactivated, false otherwise.
    def self.close_ap
      dns_line = Terrapin::CommandLine.new('snapctl', 'stop mirros-one.dns')
      dns_line.run
      NetworkManager::Bus.new.deactivate_connection('glancrsetup')
    rescue StandardError => e
      Rails.logger.warn "#{__method__} #{e.message}"
    end

    # If NetworkManager does not list connections, we can try to fetch them with iwlist.
    # Since NM manages the WiFi device, we need to catch exceptions that the device is busy.
    # @return [Array] The WiFi access points found by iwlist.
    def self.wifi_networks_via_iwlist
      line = Terrapin::CommandLine.new(
        'iwlist',
        ':iface scan | egrep "Quality|Encryption key|ESSID:\".+\""'
      )
      attempts = 0
      begin
        results = line.run(iface: NetworkManager::Bus.new.wifi_interface)&.split("\"\n")
      rescue CommandLineError => e
        Rails.logger.warn "#{__method__} #{e.message}"
        sleep 1
        retry if (attempts += 1) <= 3

        raise e
      end

      results.map! do |result|
        signal, encryption, ssid = result.split("\n").each(&:strip!)
        {
          ssid: ssid.slice(/^ESSID:"(?<ssid>.+)$/, 'ssid'),
          encryption: encryption.include?('on'),
          signal: normalize_signal_strength(signal)
        }
      end

      results
    end

    private_class_method :wifi_networks_via_iwlist

  end
end
