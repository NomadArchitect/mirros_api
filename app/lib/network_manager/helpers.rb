# frozen_string_literal: true

module NetworkManager
  # Helpers for NetworkManager-related routines. Used in SignalListeners and in Commands.
  module Helpers
    include Constants
    IP_PROTOCOL_VERSIONS = [4, 6].freeze
    IP4_PROTOCOL = 4
    IP6_PROTOCOL = 6
    CONNECTION_ACTIVATION_TIMEOUT = 10 # seconds

    def map_state(state)
      NmState.constants.select do |c|
        NmState.const_get(c).eql? state
      end.pop
    end

    def map_connectivity(connectivity_state)
      NmConnectivityState.constants.select do |c|
        NmConnectivityState.const_get(c).eql? connectivity_state
      end.pop
    end

    # @param [Integer] protocol_version Protocol version 4 or 6
    # @param [String] config_path DBus object path to a IP4Config or IP6Config
    def ip_address(protocol_version, config_path)
      unless IP_PROTOCOL_VERSIONS.include? protocol_version
        raise ArgumentError, "Protocol version must be one of #{IP_PROTOCOL_VERSIONS}"
      end
      return nil if config_path.eql?('/')

      nm_ip_o = @nm_s[config_path]
      nm_ip_i = nm_ip_o["org.freedesktop.NetworkManager.IP#{protocol_version}Config"]
      # FIXME: This only returns the first address without the prefix, maybe extend it to handle the whole array
      nm_ip_i['AddressData'].first&.dig('address')
    rescue DBus::Error => e
      Logger.error "#{__method__} #{e.message} #{e.dbus_message}"
      nil
    end

    def update_connection_ip_address(ac_path:, protocol_version: IP4_PROTOCOL, ip_config_path:)
      model = NmNetwork.find_by(active_connection_path: ac_path)
      if ip_config_path.eql?('/')
        model&.update_static_ip_settings
        return
      end

      key = "ip#{protocol_version}_address"
      values = {}
      values[key] = ip_address(protocol_version, ip_config_path)
      model&.update(values)
    end

    def change_connection_active_state(ac_path:, state:)
      value = case state
              when NmActiveConnectionState::ACTIVATED
                true
              else
                false
              end
      model = NmNetwork.find_by(active_connection_path: ac_path)
      if model.nil?
        ac_if = @nm_s[ac_path][NmInterfaces::CONNECTION_ACTIVE]
        persist_active_connection(object_path: ac_path, iface: ac_if)
      else
        attrs = { active: value }
        attrs = attrs.merge(active_connection_path: nil) unless value.eql?(true)
        model.update(attrs)
      end
    end

    # @param [DBus::ProxyObjectInterface] iface a valid NetworkManager.Connection.Active proxy
    # @return [Boolean] whether the update was successful
    def persist_active_connection(object_path:, iface:)
      nm_network = NmNetwork.find_or_initialize_by(
        uuid: iface['Uuid']
      ) do |network|
        network.connection_id = iface['Id']
        network.interface_type = iface['Type']
      end
      # TODO: Update returns a boolean, but we might want to return the NmNetwork instead.
      nm_network.assign_attributes(
        connection_settings_path: iface['Connection'],
        devices: iface['Devices'],
        active_connection_path: object_path,
        active: true,
        ip4_address: ip_address(IP4_PROTOCOL, iface['Ip4Config']),
        ip6_address: ip_address(IP6_PROTOCOL, iface['Ip6Config'])
      )
      nm_network.save!
    end

    def persist_inactive_connection(settings_path:)
      settings = NetworkManager::Commands.instance.settings_for_connection_path(connection_path: settings_path)
      model = NmNetwork.find_or_initialize_by(
        uuid: settings.dig('connection', 'uuid')
      ) do |network|
        network.connection_id = settings.dig('connection', 'id')
        network.interface_type = settings.dig('connection', 'type')
      end
      model.assign_attributes(
        connection_settings_path: settings_path,
        ip4_address: settings.dig('ipv4', 'address-data', 0, 'address'),
        ip6_address: settings.dig('ipv6', 'address-data', 0, 'address')
      )
      model.save!
    rescue StandardError => e
      Logger.error e.message
    end

    def retry_wrap(max_attempts: 3, &block)
      attempts = 0
      begin
        yield block
      rescue DBus::Error => e
        # Rails.logger.warn "#{__method__} #{e.message}"
        sleep 1
        retry if (attempts += 1) <= max_attempts

        raise e
      end
    end
  end
end
