# frozen_string_literal: true

return if OS.linux?

require 'dbus'

# Static dummy replacement for NetworkManager::Bus class in case we're not running on Linux host.
module NetworkManager
  class Bus
    include NetworkManager::Constants
    attr_reader :wifi_interface

    def initialize
      @wifi_interface = 'wlan0'
    end

    def state_hash
      {
        state: state,
        connectivity: connectivity,
        wifi_signal: { signal: 70, ssid: 'Bogus WiFi' },
        primary_connection: primary_connection_as_model
      }
    end

    def add_predefined_connections
      true
    end

    def delete_all_connections
      true
    end

    def activate_new_wifi_connection(_ssid, _password)
      # Ensures we don't end up with two connection profiles for the same SSID.
      true
    end

    def activate_connection(_id)
      true
    end

    def deactivate_connection(id)
      true
    end

    def delete_connection(id)
      true
    end

    def connection_active?(id)
      true
    end

    def connecting?
      state.eql?(NmState::CONNECTING)
    end

    def connected_local?
      state.eql?(NmState::CONNECTED_LOCAL)
    end

    def connected_site?
      state.eql?(NmState::CONNECTED_SITE)
    end

    def connected?
      state.eql?(NmState::CONNECTED_GLOBAL)
    end

    def any_connectivity?
      connected? || connecting? || connected_local? || connected_site?
    end

    def connectivity_check_available?
      true
    end

    def connectivity
      NmConnectivityState::FULL
    end

    def state
      NmState::CONNECTED_GLOBAL
    end

    def primary_connection
      '/org/freedesktop/NetworkManager/ActiveConnection/1'
    end

    def nm_version
      '1.32.12'
    end

    def uuid_for_connection(id)
      Digest::UUID.uuid_v5('networks', id)
    end

    def model_for_active_connection(ac_path)

      attributes = {
        'Id' => 'network',
        'Uuid' => 'F3933F85-7D20-4FAC-A56E-1C3C89A70B88',
        'Type' => '802-11-wireless'
      }
      ip4_address = '0.0.0.0'
      ip6_address = '1a7a:905f:13c7:6675:0708:ee0d:5859:844b'

      ::NmNetwork.new attributes, ip4_address, ip6_address, ac_path
    end

    def primary_connection_as_model
      connection = primary_connection
      if connection.eql?('/')
        nil
      else
        model_for_active_connection(connection)
      end
    end
  end
end

