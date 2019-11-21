# frozen_string_literal: true

require 'singleton'
require 'dbus'

module NetworkManager
  # High-level commands. Proxied NetworkManager D-Bus methods are excluded from
  # RubyResolve inspections to prevent RuboCop error messages.
  class Commands
    include Singleton
    include Constants
    attr_reader :wifi_interface

    IP_PROTOCOL_VERSIONS = [4, 6].freeze
    IP4_PROTOCOL = 4
    IP6_PROTOCOL = 6
    WIFI_CONNECT_TIMEOUT = 45 # seconds
    WIFI_SCAN_TIMEOUT = 20 # seconds
    CONNECTION_ACTIVATION_TIMEOUT = 10 # seconds

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
      @nm_s = DBus.system_bus['org.freedesktop.NetworkManager']
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
        ap = scan_for_ssid(ssid)
        raise StandardError, "no Access Point found for #{ssid}" if ap.blank?
      end
      # noinspection RubyResolve
      _settings, active_conn_path = @nm_i.AddAndActivateConnection(
        conn, @wifi_device, ap
      )
      persist_once_active(path: active_conn_path, timeout: WIFI_CONNECT_TIMEOUT)
    end

    def list_access_point_paths
      wifi_device = @wifi_device || list_devices[:wifi]&.first
      nm_wifi_s = @nm_s[wifi_device]
      nm_wifi_i = nm_wifi_s[NmInterfaces::DEVICE_WIRELESS]
      # noinspection RubyResolve
      nm_wifi_i.GetAllAccessPoints
    end

    # Activates a NetworkManager connection with the given ID. If the connection is already active,
    # @param [String] connection_id ID of the connection to activate.
    # @return [Boolean] If the persistence update was successful
    def activate_connection(connection_id)
      # TODO: Check if we can always pass base paths
      # noinspection RubyResolve
      connection_path = @nm_i.ActivateConnection(
        connection_object_path(connection_id), '/', '/'
      )
      persist_once_active(
        path: connection_path,
        timeout: CONNECTION_ACTIVATION_TIMEOUT
      )
    end

    def deactivate_connection(connection_id)
      # FIXME: Current polling implementation is too fragile to rely on connection state in the DB.
      # Maybe revert to network.active once NM signal listeners are implemented.
      network = NmNetwork.find_by(connection_id: connection_id)
      active_connection_path = @nm_i['ActiveConnections'].filter do |connection_path|
        nm_con_i = @nm_s[connection_path][NmInterfaces::CONNECTION_ACTIVE]
        nm_con_i['Id'].eql?(connection_id)
      end.first
      return if active_connection_path.blank?

      # noinspection RubyResolve
      @nm_i.DeactivateConnection(active_connection_path)
      network.update(devices: nil, active: false, ip4_address: nil, ip6_address: nil)
    end

    def delete_connection(connection_id: nil, connection_path: nil)
      connection_path ||= connection_object_path(connection_id)
      conn_o = @nm_s[connection_path]
      conn_i = conn_o['org.freedesktop.NetworkManager.Settings.Connection']
      conn_i.Delete
    rescue DBus::Error => e
      Rails.logger.error e.dbus_message.params
      Rails.logger.error e.dbus_message
    end

    def delete_all_wifi_connections
      # Use Model scopes to exclude system-defined and LAN connections
      NmNetwork.user_defined.wifi.each do |network|
        wifi_conn = wifi_connection_path(network.id)
        delete_connection(connection_path: wifi_conn) unless wifi_conn.nil?
        network.destroy
      end
    end

    def list_devices
      devices = {
        wifi: [],
        ethernet: []
      }
      # noinspection RubyResolve
      @nm_i.GetDevices.each do |dev|
        nm_dev_i = @nm_s[dev]['org.freedesktop.NetworkManager.Device']
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
      nm_ip4_i = nm_ip4_o['org.freedesktop.NetworkManager.IP4Config']
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

    # @param [String] connection_id Name of the NM connection to sync.
    # @return [NmNetwork, nil] The added or updated NmNetwork model, or nil if
    # NetworkManager could not find a connection with the given ID.
    def sync_db_to_nm_connection(connection_id: nil)
      settings = nm_settings_for_connection(connection_id: connection_id)
      return if settings.nil?

      persist_inactive_connection(settings: settings)
    end

    # Retrieves the SSID and signal strength of the currently active access point.
    # Returns nil for both values if no access point is active.
    # @return [Hash] Connected SSID and its signal strength in percent (e.g. 70).
    def wifi_status
      ret = { ssid: nil, signal: nil }
      nm_wifi_if = @nm_s[@wifi_device][NmInterfaces::DEVICE_WIRELESS]
      active_ap_path = nm_wifi_if['ActiveAccessPoint']
      unless active_ap_path.eql?('/')
        ap_if = @nm_s[active_ap_path][NmInterfaces::ACCESS_POINT]
        ret[:ssid] = ap_if['Ssid'].pack('U*')
        ret[:signal] = ap_if['Strength'].to_i
      end
    ensure
      ret
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
      list_access_point_paths.filter do |ap|
        nm_ap_o = @nm_s[ap]
        nm_ap_i = nm_ap_o[NmInterfaces::ACCESS_POINT]
        nm_ap_i['Ssid'].pack('U*').eql? ssid # NM returns byte-array
      end.shift
    end

    # @param [String] ssid Scan for a given SSID, otherwise do a general scan.
    # @return [String]
    def scan_for_ssid(ssid = '')
      nm_wifi_s = @nm_s[@wifi_device]
      nm_wifi_i = nm_wifi_s[NmInterfaces::DEVICE_WIRELESS]

      # NM 1.2.2 doesn't have Device.Wireless LastScan property, so we need to
      # listen on the DBus signal when new AP's are added. Assumes the AP
      loop = DBus::Main.new
      loop << DBus::SystemBus.instance
      nm_wifi_i.on_signal('AccessPointAdded') do |ap_path|
        ap_i = @nm_s[ap_path][NmInterfaces::ACCESS_POINT]
        if ap_i['Ssid'].pack('U*').eql?(ssid)
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
      Rails.logger.error e.dbus_message.params
      nil
    end

    def add_connection(connection_settings)
      nm_settings_i = @nm_s['/org/freedesktop/NetworkManager/Settings'][NmInterfaces::SETTINGS]
      # noinspection RubyResolve
      settings_path = nm_settings_i.AddConnection(connection_settings)
      nm_conn_i = @nm_s[settings_path][NmInterfaces::SETTINGS_CONNECTION]
      # noinspection RubyResolve
      persist_inactive_connection(settings: nm_conn_i.GetSettings)
    end

    # Retrieves the NetworkManager connection settings for a given connection ID.
    # @param [String] connection_id ID of the connection
    # @return [Hash,nil] Settings hash, or nil if NetworkManager cannot find a connection with this ID.
    def nm_settings_for_connection(connection_id: nil)
      nm_s_o = @nm_s['/org/freedesktop/NetworkManager/Settings']
      nm_s_i = nm_s_o[NmInterfaces::SETTINGS]
      nm_s_i['Connections'].filter do |con|
        nm_conn_o = @nm_s[con]
        nm_conn_i = nm_conn_o[NmInterfaces::SETTINGS_CONNECTION]
        # noinspection RubyResolve
        settings = nm_conn_i.GetSettings
        break settings if settings.dig('connection', 'id').eql?(connection_id)
      end
    end

    # @param [DBus::ProxyObjectInterface] active_connection_if a valid NetworkManager.Connection.Active proxy
    # @return [Boolean] whether the update was successful
    def persist_active_connection(active_connection_if:)
      # wait until connection is active
      # see https://developer.gnome.org/NetworkManager/1.2/nm-dbus-types.html#NMActiveConnectionState
      sleep 0.25 until active_connection_if['State'].eql? NmActiveConnectionState::ACTIVATED
      nm_network = NmNetwork.find_or_initialize_by(
        uuid: active_connection_if['Uuid']
      ) do |network|
        network.connection_id = active_connection_if['Id']
        network.interface_type = active_connection_if['Type']
      end
      # TODO: Update returns a boolean, but we might want to return the NmNetwork instead.
      nm_network.update(
        devices: active_connection_if['Devices'],
        active: true,
        ip4_address: ip_address(IP4_PROTOCOL, active_connection_if['Ip4Config']),
        ip6_address: ip_address(IP6_PROTOCOL, active_connection_if['Ip6Config'])
      )
    end

    def persist_inactive_connection(settings: {})
      NmNetwork.create(
        uuid: settings.dig('connection', 'uuid'),
        connection_id: settings.dig('connection', 'id'),
        interface_type: settings.dig('connection', 'type'),
        devices: nil,
        active: false,
        ip4_address: settings.dig('ipv4', 'address-data', 0, 'address'),
        ip6_address: settings.dig('ipv6', 'address-data', 0, 'address')
      )
    end

    def persist_once_active(path: nil, timeout: CONNECTION_ACTIVATION_TIMEOUT)
      attempts = 0
      begin
        # FIXME: This becomes obsolete once persistence is handled through signals
        active_conn_i = @nm_s[path][NmInterfaces::CONNECTION_ACTIVE]
        persist_active_connection(active_connection_if: active_conn_i)
      rescue DBus::Error => e
        sleep 1
        retry if (attempts += 1) <= timeout

        raise e
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
