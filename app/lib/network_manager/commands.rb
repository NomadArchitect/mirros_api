require 'singleton'

module NetworkManager
  # High-level commands
  class Commands
    include Singleton
    include Constants

    IP_PROTOCOL_VERSIONS = [4, 6].freeze
    IP4_PROTOCOL = 4
    IP6_PROTOCOL = 6

    def initialize
      @nm_s = DBus.system_bus['org.freedesktop.NetworkManager']
      @nm_o = @nm_s['/org/freedesktop/NetworkManager']
      @nm_i = @nm_o['org.freedesktop.NetworkManager']
      @wifi_device = device_path('wlp3s0') # FIXME: Hardcoded for Ubuntu Core
    end

    def activate_new_wifi_connection(ssid, password)
      conn = { '802-11-wireless-security' => { 'psk' => password} }
      ap = ap_object_path_for_ssid(ssid)
      raise StandardError, "no Access Point found for #{ssid}" if ap.blank?

      _settings, active_connection = @nm_i.AddAndActivateConnection(
        conn, @wifi_device, ap
      )
      active_conn_o = @nm_s[active_connection]
      active_conn_i = active_conn_o['org.freedesktop.NetworkManager.Connection.Active']

      # wait until connection is active, see https://developer.gnome.org/NetworkManager/1.2/nm-dbus-types.html#NMActiveConnectionState
      sleep 0.25 until active_conn_i['State'].eql? NmActiveConnectionState::ACTIVATED
      # FIXME: Break if connection is never activated

      save_network(conn_if: active_conn_i, active: true)
    end

    def list_access_point_paths
      nm_wifi_s = @nm_s[@wifi_device]
      nm_wifi_i = nm_wifi_s['org.freedesktop.NetworkManager.Device.Wireless']
      nm_wifi_i.GetAllAccessPoints()
    end

    def activate_connection(connection_id)
      # TODO: Check if we can always pass base paths
      @nm_i.ActivateConnection(connection_object_path(connection_id), '/', '/')
    end

    def deactivate_connection(connection_id)
      @nm_i.DeactivateConnection(connection_object_path(connection_id))
    end

    def delete_connection(connection_id)
      conn_path = connection_object_path(connection_id)
      conn_o = @nm_s[conn_path]
      conn_i = conn_o['org.freedesktop.NetworkManager.Settings.Connection']

      conn_i.Delete()
    rescue DBus::Error => e
      Rails.logger.error e.dbus_message.params
      Rails.logger.error e.dbus_message
    end

    def list_devices
      devices = {
        wifi: [],
        ethernet: []
      }
      @nm_i.GetDevices.each do |dev|
        nm_dev_o = @nm_s[dev]
        nm_dev_i = nm_dev_o['org.freedesktop.NetworkManager.Device']
        device_state = nm_dev_i['State']
        next unless device_state.between? NMDeviceState::DISCONNECTED, NMDeviceState::ACTIVATED

        dev_info = { interface: nm_dev_i['Interface'], state: device_state }
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
      stored_connection = NmNetwork.find_by(id: connection_id)
      nm_settings_o = @nm_s['/org/freedesktop/NetworkManager/Settings']
      nm_settings_i = nm_settings_o['org.freedesktop.NetworkManager.Settings']

      nm_settings_i.GetConnectionByUuid(stored_connection.uuid)
    end

    def ap_object_path_for_ssid(ssid)
      list_access_point_paths.filter do |ap|
        nm_ap_o = @nm_s[ap]
        nm_ap_i = nm_ap_o['org.freedesktop.NetworkManager.AccessPoint']
        nm_ap_i['Ssid'].pack('U*').eql? ssid # NM returns byte-array
      end.shift
    end

    def device_path(device)
      @nm_i.GetDeviceByIpIface(device)
    end

    # @param [Integer] protocol_version
    def ip_addresses(protocol_version, config_path)
      unless IP_PROTOCOL_VERSIONS.include? protocol_version
        raise ArgumentError, "Protocol version must be one of #{IP_PROTOCOL_VERSIONS}"
      end

      nm_ip_o = @nm_s[config_path]
      nm_ip_i = nm_ip_o["org.freedesktop.NetworkManager.IP#{protocol_version}Config"]
      nm_ip_i['AddressData']
    end

    # @param [DBus::ProxyObjectInterface] conn_if a valid NetworkManager.Connection.Active proxy
    # @param [Boolean] active If the connection is currently active
    # @return [NmNetwork] the created network connection
    def save_network(conn_if:, active: true)
      NmNetwork.create(
        uuid: conn_if['Uuid'],
        id: conn_if['Id'],
        interface_type: conn_if['Type'],
        devices: conn_if['Devices'],
        active: active,
        ip4_addresses: ip_addresses(IP4_PROTOCOL, conn_if['Ip4Config']),
        ip6_addresses: ip_addresses(IP6_PROTOCOL, conn_if['Ip6Config'])
      )
    end
  end
end
