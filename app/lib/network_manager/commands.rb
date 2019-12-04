# frozen_string_literal: true

require 'singleton'
require 'dbus'

module NetworkManager
  # High-level commands. Proxied NetworkManager D-Bus methods are excluded from
  # RubyResolve inspections to prevent RuboCop error messages.
  class Commands
    include Singleton
    include Constants
    include Helpers
    attr_reader :wifi_interface

    IP_PROTOCOL_VERSIONS = [4, 6].freeze
    IP4_PROTOCOL = 4
    IP6_PROTOCOL = 6
    WIFI_CONNECT_TIMEOUT = 45 # seconds
    WIFI_SCAN_TIMEOUT = 20 # seconds

    # for type casting, see https://developer.gnome.org/NetworkManager/1.16/gdbus-org.freedesktop.NetworkManager.IP4Config.html#gdbus-property-org-freedesktop-NetworkManager-IP4Config.AddressData
    # D-Bus proxy calls String.bytesize, so we require string keys.
    # noinspection RubyStringKeysInHashInspection
    GLANCRSETUP_CONNECTION = {
      'connection' => {
        'id' => 'glancrsetup',
        'type' => '802-11-wireless',
        'autoconnect' => false
      },
      '802-11-wireless' => {
        'ssid' => DBus.variant('ay', 'glancr setup'.bytes),
        'mode' => 'ap'
      },
      'ipv4' => {
        'address-data' => DBus.variant('aa{sv}', [{ 'address' => '192.168.8.1', 'prefix' => DBus.variant('u', 32) }]),
        'method' => 'manual',
        # dns: Array of IP addresses of DNS servers (as network-byte-order integers)
        # see https://developer.gnome.org/NetworkManager/stable/nm-settings.html#id-1.2.7.4.18
        # we want 192.168.8.1 (= localhost) as our static DNS server
        # -> reverse for network byte order: 1.8.168.192
        # -> binary form: 00000001.00001000.10101000.11000000
        # -> decimal representation (without octet dots): 17344704
        # -> Ruby style guide: underscore separators
        'dns' => DBus.variant('au', [17_344_704]),
        'gateway' => '192.168.8.1'
      }
      # TODO: IPv6 address settings for AP connection
    }.freeze
    # noinspection RubyStringKeysInHashInspection
    GLANCRLAN_CONNECTION = {
      'connection' => {
        'id' => 'glancrlan',
        'type' => '802-3-ethernet',
        'autoconnect' => false
      }
    }.freeze

    # TODO: Refactor to less lines if object is just needed for a single interface
    # see https://www.rubydoc.info/github/mvidner/ruby-dbus/file/doc/Reference.md#Errors

    def initialize
      @nm_s = DBus::ASystemBus.new['org.freedesktop.NetworkManager']
      @nm_o = @nm_s['/org/freedesktop/NetworkManager']
      @nm_i = @nm_o['org.freedesktop.NetworkManager']

      wifi_device_list = list_devices[:wifi]&.first # FIXME: This just picks the first listed wifi interface
      @wifi_interface = wifi_device_list&.fetch(:interface)
      @wifi_device = wifi_device_list&.fetch(:path)
    end

    def add_predefined_connections
      add_connection(GLANCRSETUP_CONNECTION)
      add_connection(GLANCRLAN_CONNECTION)
    end

    # @param [String] ssid SSID of the access point for which a new connection should be established.
    # @param [String] password Passphrase for this access point. @see https://developer.gnome.org/NetworkManager/1.2/ref-settings.html#id-1.4.3.31.1
    def activate_new_wifi_connection(ssid, password)
      # D-Bus proxy calls String.bytesize, so we can't use symbol keys.
      # noinspection RubyStringKeysInHashInspection
      conn = { '802-11-wireless-security' => { 'psk' => password } }
      ap = ap_object_path_for_ssid(ssid)
      if ap.blank?
        Rails.logger.warn "AP for given SSID #{ssid} not known yet, initiating scan"
        ap = scan_for_ssid(ssid)
      end
      # noinspection RubyResolve
      @nm_i.AddAndActivateConnection(conn, @wifi_device, ap)
    end

    # List all access points currently available on the primary NetworkManager WiFi device. Includes hidden SSIDs.
    # @return [Array] List of DBus object paths.
    def list_access_point_paths
      attempts = 0
      begin
        nm_wifi_i = @nm_s[@wifi_device][NmInterfaces::DEVICE_WIRELESS]
        # noinspection RubyResolve
        nm_wifi_i['AccessPoints']
      rescue DBus::Error => e
        sleep 1
        retry if (attempts += 1) <= 3

        raise e
      end
    end

    # Activates a NetworkManager connection with the given ID. If the connection is already active,
    # @param [String] connection_id ID of the connection to activate.
    # @return [String] The new active connection path
    def activate_connection(connection_id)
      network = NmNetwork.find_by(connection_id: connection_id)
      return if network.active

      # noinspection RubyResolve
      @nm_i.ActivateConnection(network.connection_settings_path, '/', '/')
    end

    # @param [String] connection_id The connection to deactivate
    # @return [nil]
    def deactivate_connection(connection_id)
      network = NmNetwork.find_by(connection_id: connection_id)
      return unless network.active

      # noinspection RubyResolve
      @nm_i.DeactivateConnection(network.active_connection_path)
    end

    def delete_connection(connection_id: nil, connection_path: nil)
      connection_path ||= NmNetwork.find_by(connection_id: connection_id).connection_settings_path
      conn_o = @nm_s[connection_path]
      conn_i = conn_o[NmInterfaces::SETTINGS_CONNECTION]
      conn_i.Delete
    rescue DBus::Error => e
      Rails.logger.error e.message
    end

    def delete_all_wifi_connections
      # Use Model scopes to exclude system-defined and LAN connections
      NmNetwork.user_defined.wifi.each do |network|
        delete_connection(connection_path: network.connection_settings_path)
      end
    end

    def list_devices
      devices = {
        wifi: [],
        ethernet: []
      }
      # noinspection RubyResolve
      @nm_i.GetDevices.each do |dev|
        nm_dev_i = @nm_s[dev][NmInterfaces::DEVICE]
        device_state = nm_dev_i['State']
        unless device_state.between? NMDeviceState::DISCONNECTED, NMDeviceState::ACTIVATED
          next
        end

        dev_info = { interface: nm_dev_i['Interface'], state: device_state, path: dev }
        case nm_dev_i['DeviceType']
        when NmDeviceType::ETHERNET
          devices[:ethernet] << dev_info
        when NmDeviceType::WIFI
          devices[:wifi] << dev_info
        else
          # TODO: Maybe add support for additional devices later.
        end
      end
      devices
    end

    def ip_for_device(device_name)
      dev = device_path(device_name)

      nm_dev_o = @nm_s[dev]
      nm_dev_i = nm_dev_o[NmInterfaces::DEVICE]
      ip4config_path = nm_dev_i['Ip4Config']

      return nil if ip4config_path.eql? '/'

      nm_ip4_o = @nm_s[ip4config_path]
      nm_ip4_i = nm_ip4_o[NmInterfaces::IP4CONFIG]
      nm_ip4_i['AddressData'].first['address']
    end

    # In case a connection object path is stale and no longer present on NMs
    # side, NM would throw misleading errors about the Properties interface
    # missing from this object. In that case, the connection is a) not active
    # and b) probably not the connection we are looking for.
    # @param [String] connection_id Name of the connection to check.
    # @return [Boolean] Whether the connection is active.
    def connection_active?(connection_id)
      @nm_i['ActiveConnections'].any? do |con|
        nm_con_o = @nm_s[con]
        nm_con_i = nm_con_o[NmInterfaces::CONNECTION_ACTIVE]
        nm_con_i['Id'].eql? connection_id
      end
    rescue StandardError => e
      Rails.logger.error "
                         #{__method__} encountered probably stale
connection while searching for #{connection_id} #{e.message}
                         "
      false
    end

    def sync_all_connections
      @nm_settings_i = @nm_s['/org/freedesktop/NetworkManager/Settings'][NmInterfaces::SETTINGS]
      @nm_settings_i['Connections'].each do |settings_path|
        persist_inactive_connection(settings_path: settings_path)
      end
      @nm_i['ActiveConnections'].each do |ac_path|
        ac_if = @nm_s[ac_path][NmInterfaces::CONNECTION_ACTIVE]
        persist_active_connection(object_path: ac_path, iface: ac_if)
      end
    end

    # Retrieves SSID and signal strength of the currently active AccessPoint.
    # Returns nil for both values if no access point is active or an error occurred.
    # @return [Hash] Connected SSID and its signal strength in percent (e.g. 70)
    def wifi_status
      nm_wifi_if = @nm_s[@wifi_device][NmInterfaces::DEVICE_WIRELESS]
      active_ap_path = nm_wifi_if['ActiveAccessPoint']
      return { ssid: nil, signal: nil } if active_ap_path.eql?('/')

      ap_if = @nm_s[active_ap_path][NmInterfaces::ACCESS_POINT]
      {
        ssid: ap_if['Ssid'].pack('U*'), signal: ap_if['Strength'].to_i
      }
    rescue DBus::Error => e
      Rails.logger.error e.message
      { ssid: nil, signal: nil }
    end

    def connectivity
      @nm_i['Connectivity']
    end

    def state
      @nm_i['State']
    end

    def primary_connection
      @nm_i['PrimaryConnection']
    end

    def settings_for_connection_path(connection_path:)
      retry_wrap max_attempts: 3 do
        nm_conn_o = @nm_s[connection_path]
        nm_conn_i = nm_conn_o[NmInterfaces::SETTINGS_CONNECTION]
        # noinspection RubyResolve
        nm_conn_i.GetSettings
      end
    end

    private

    # @param [String] connection_id The given ID of a connection. Assumes that a
    # NmNetwork entry with this ID exists in the DB.
    # @return [String] The DBus object path for this connection.
    def connection_object_path(connection_id)
      stored_connection = NmNetwork.find_by(connection_id: connection_id)
      if stored_connection.nil?
        raise ArgumentError, "#{__method__} couldn't find NmNetwork with connection_id #{connection_id}"
      end

      nm_settings_o = @nm_s['/org/freedesktop/NetworkManager/Settings']
      nm_settings_i = nm_settings_o[NmInterfaces::SETTINGS]
      # noinspection RubyResolve
      nm_settings_i.GetConnectionByUuid(stored_connection.uuid)
    end

    # @param [String] ssid
    # @return [String, nil] The DBus object path for the given connection or nil if NM does not have it.
    def ap_object_path_for_ssid(ssid)
      candidates = []
      list_access_point_paths.each do |ap_path|
        details = ap_details(ap_path)
        candidates.push(details) if details.dig(:ssid).eql?(ssid.to_s)
      end
      candidates.empty? ? nil : candidates.max { |c| c[:strength] }[:ap_path]
    end

    # @param [String] ap_path Valid DBus access point object path
    # @return [Hash] Hash containing the given path, ssid as String and strength as Integer.
    def ap_details(ap_path)
      nm_ap_i = @nm_s[ap_path][NmInterfaces::ACCESS_POINT]
      {
        ap_path: ap_path,
        ssid: nm_ap_i['Ssid']&.pack('U*'), # NM returns byte-array
        strength: nm_ap_i['Strength']
      }
    rescue DBus::Error => e
      Rails.logger.error "#{__method__} L:#{__LINE__} #{e.message}"
      {}
    end

    # @param [String] ssid Scan for a given SSID, otherwise do a general scan.
    # @return [String]
    def scan_for_ssid(ssid = '')
      nm_wifi_i = @nm_s[@wifi_device][NmInterfaces::DEVICE_WIRELESS]
      # NM 1.2.2 doesn't have Device.Wireless LastScan property, so we need to
      # listen on the DBus signal when new AP's are added. Assumes the AP
      loop = DBus::Main.new
      loop << DBus::SystemBus.instance
      nm_wifi_i.on_signal('AccessPointAdded') do |ap_path|
        ap_i = @nm_s[ap_path][NmInterfaces::ACCESS_POINT]
        if ap_i['Ssid'].eql?(ssid.bytes)
          loop.quit
          Thread.current[:output] = ap_path
          Thread.current.exit
        end
      end
      thr = Thread.new { loop.run }
      request_scan(dbus_wifi_iface: nm_wifi_i, ssid: ssid)
      time_elapsed = 0
      result = while time_elapsed <= WIFI_SCAN_TIMEOUT
                 sleep 2
                 time_elapsed += 2
                 Rails.logger.warn "searching for #{ssid}, #{time_elapsed} sec elapsed"
                 break thr[:output] unless thr[:output].nil?
               end
      return result if result.present?

      loop.quit
      thr.kill
      raise StandardError, "NM could not find AP for given SSID #{ssid}"
    end

    def device_path(interface)
      # noinspection RubyResolve
      @nm_i.GetDeviceByIpIface(interface)
    end

    # @param [Integer] protocol_version
    def ip_address(protocol_version, config_path)
      unless IP_PROTOCOL_VERSIONS.include? protocol_version
        raise ArgumentError, "Protocol version must be one of #{IP_PROTOCOL_VERSIONS}"
      end

      nm_ip_o = @nm_s[config_path]
      nm_ip_i = nm_ip_o["org.freedesktop.NetworkManager.IP#{protocol_version}Config"]
      # TODO: This only returns the first address without the prefix, maybe extend it to handle the whole array
      nm_ip_i['AddressData'].first&.dig('address')
    end

    # Retrieves the connection object path of a given connection UUID.
    # @param [String] connection_uuid UUID of an existing NetworkManager connection
    # @return [String, nil] The connection's DBus object path or nil if the connection does not exist.
    def wifi_connection_path(connection_uuid)
      nm_settings_o = @nm_s['/org/freedesktop/NetworkManager/Settings']
      nm_settings_i = nm_settings_o[NmInterfaces::SETTINGS]
      # noinspection RubyResolve
      nm_settings_i.GetConnectionByUuid(connection_uuid)
    rescue DBus::Error => e
      Rails.logger.error e.message
      nil
    end

    def add_connection(connection_settings)
      nm_settings_i = @nm_s['/org/freedesktop/NetworkManager/Settings'][NmInterfaces::SETTINGS]
      # noinspection RubyResolve
      settings_path = nm_settings_i.AddConnection(connection_settings)
      persist_inactive_connection(settings_path: settings_path)
    end

    # Retrieves the NetworkManager connection settings for a given connection ID.
    # @param [String] connection_id ID of the connection
    # @return [Hash,nil] Settings hash, or nil if NetworkManager cannot find a connection with this ID.
    def nm_settings_for_connection_id(connection_id: nil)
      nm_s_o = @nm_s['/org/freedesktop/NetworkManager/Settings']
      nm_s_i = nm_s_o[NmInterfaces::SETTINGS]
      nm_s_i['Connections'].filter do |con|
        settings = settings_for_connection_path(con)
        break settings if settings.dig('connection', 'id').eql?(connection_id)
      end
    end

    def request_scan(dbus_wifi_iface:, ssid: '')
      # noinspection RubyResolve, RubyStringKeysInHashInspection
      dbus_wifi_iface.RequestScan('ssid' => DBus.variant('aay', [ssid.bytes]))
    rescue DBus::Error => e
      # Device is probably already scanning, avoid error bubbling.
      Rails.logger.error "#{__method__}: #{e.message}"
    end
  end
end
