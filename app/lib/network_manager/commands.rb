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

    def activate_new_wifi_connection(ssid, password)
      # D-Bus proxy calls String.bytesize, so we can't use symbol keys.
      # noinspection RubyStringKeysInHashInspection
      conn = { '802-11-wireless-security' => { 'psk' => password} }
      ap = ap_object_path_for_ssid(ssid)
      raise StandardError, "no Access Point found for #{ssid}" if ap.blank?

      # noinspection RubyResolve
      _settings, active_connection = @nm_i.AddAndActivateConnection(
        conn, @wifi_device, ap
      )
      active_conn_o = @nm_s[active_connection]
      active_conn_i = active_conn_o['org.freedesktop.NetworkManager.Connection.Active']

      # wait until connection is active, see https://developer.gnome.org/NetworkManager/1.2/nm-dbus-types.html#NMActiveConnectionState
      sleep 0.25 until active_conn_i['State'].eql? NmActiveConnectionState::ACTIVATED
      # FIXME: Break if connection is never activated

      persist_active_connection(active_connection_if: active_conn_i)
    end

    def list_access_point_paths
      nm_wifi_s = @nm_s[@wifi_device]
      nm_wifi_i = nm_wifi_s['org.freedesktop.NetworkManager.Device.Wireless']
      # noinspection RubyResolve
      nm_wifi_i.GetAllAccessPoints
    end

    def activate_connection(connection_id)
      # TODO: Check if we can always pass base paths
      # noinspection RubyResolve
      connection_path = @nm_i.ActivateConnection(
        connection_object_path(connection_id), '/', '/'
      )
      persist_active_connection(
        active_connection_if: @nm_s[connection_path]['org.freedesktop.NetworkManager.Connection.Active']
      )
    end

    def deactivate_connection(connection_id)
      # TODO: Maybe cleaner to get the connection from active connections?
      network = NmNetwork.find_by(connection_id: connection_id)
      if network.devices.blank?
        return
      else
        device = JSON.parse(network.devices).first
      end

      active_connection_path = @nm_s[device]['org.freedesktop.NetworkManager.Device']['ActiveConnection']
      # noinspection RubyResolve
      @nm_i.DeactivateConnection(active_connection_path)
      network.update(devices: nil, active: false, ip4_address: nil, ip6_address: nil)
    end

    def delete_connection(connection_id: nil, connection_path: nil)
      connection_path ||= connection_object_path(connection_id)
      conn_o = @nm_s[connection_path]
      conn_i = conn_o['org.freedesktop.NetworkManager.Settings.Connection']

      conn_i.Delete
      NmNetwork.find_by(connection_id: connection_id).destroy
    rescue DBus::Error => e
      Rails.logger.error e.dbus_message.params
      Rails.logger.error e.dbus_message
    end

    def delete_all_wifi_connections
      wifi_connection_paths.each { |wifi_conn| delete_connection(connection_path: wifi_conn) }
      # Use Model scopes to exclude system-defined and LAN connections
      NmNetwork.user_defined.wifi.destroy_all
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

        dev_info = {interface: nm_dev_i['Interface'], state: device_state}
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
      nm_dev_i = nm_dev_o['org.freedesktop.NetworkManager.Device']
      ip4config_path = nm_dev_i['Ip4Config']

      return nil if ip4config_path.eql? '/'

      nm_ip4_o = @nm_s[ip4config_path]
      nm_ip4_i = nm_ip4_o['org.freedesktop.NetworkManager.IP4Config']
      nm_ip4_i['AddressData'].first['address']
    end

    def connection_active?(connection_id)
      @nm_i['ActiveConnections'].any? do |con|
        nm_con_o = @nm_s[con]
        nm_con_i = nm_con_o['org.freedesktop.NetworkManager.Connection.Active']
        nm_con_i['Id'].eql? connection_id
      end
    end

    private

    def connection_object_path(connection_id)
      stored_connection = NmNetwork.find_by(connection_id: connection_id)
      nm_settings_o = @nm_s['/org/freedesktop/NetworkManager/Settings']
      nm_settings_i = nm_settings_o['org.freedesktop.NetworkManager.Settings']
      # noinspection RubyResolve
      nm_settings_i.GetConnectionByUuid(stored_connection.uuid)
    end

    def ap_object_path_for_ssid(ssid)
      list_access_point_paths.filter do |ap|
        nm_ap_o = @nm_s[ap]
        nm_ap_i = nm_ap_o['org.freedesktop.NetworkManager.AccessPoint']
        nm_ap_i['Ssid'].pack('U*').eql? ssid # NM returns byte-array
      end.shift
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

    def wifi_connection_paths
      NmNetwork.user_defined.wifi.to_a.map do |wifi_conn|
        nm_settings_o = @nm_s['/org/freedesktop/NetworkManager/Settings']
        nm_settings_i = nm_settings_o['org.freedesktop.NetworkManager.Settings']
        # noinspection RubyResolve
        nm_settings_i.GetConnectionByUuid(wifi_conn.uuid)
      end
    end

    def add_connection(connection_settings)
      nm_settings_i = @nm_s['/org/freedesktop/NetworkManager/Settings']['org.freedesktop.NetworkManager.Settings']
      # noinspection RubyResolve
      settings_path = nm_settings_i.AddConnection(connection_settings)
      nm_conn_i = @nm_s[settings_path]['org.freedesktop.NetworkManager.Settings.Connection']
      # noinspection RubyResolve
      settings = nm_conn_i.GetSettings

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

    # @param [DBus::ProxyObjectInterface] active_connection_if a valid NetworkManager.Connection.Active proxy
    # @return [NmNetwork] the created network connection
    def persist_active_connection(active_connection_if:)
      sleep 0.25 until active_connection_if['State'].eql? NmActiveConnectionState::ACTIVATED
      nm_network = NmNetwork.find_or_initialize_by(
        uuid: active_connection_if['Uuid']
      ) do |network|
        network.connection_id = active_connection_if['Id']
        network.interface_type = active_connection_if['Type']
      end
      nm_network.update(
        devices: active_connection_if['Devices'],
        active: true,
        ip4_address: ip_address(IP4_PROTOCOL, active_connection_if['Ip4Config']),
        ip6_address: ip_address(IP6_PROTOCOL, active_connection_if['Ip6Config'])
      )
    end
  end
end
