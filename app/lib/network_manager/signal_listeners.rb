# frozen_string_literal: true

require 'singleton'
require 'dbus'

module NetworkManager
  # Convention: ac = "active connection"
  class SignalListeners
    include Constants
    include Helpers
    include Singleton

    def initialize
      @nm_s = DBus.system_bus['org.freedesktop.NetworkManager']
      @nm_o = @nm_s['/org/freedesktop/NetworkManager']
      @nm_i = @nm_o['org.freedesktop.NetworkManager']
      @nm_settings_i = @nm_s['/org/freedesktop/NetworkManager/Settings'][NmInterfaces::SETTINGS]
      @loop = DBus::Main.new
      @loop << DBus::SystemBus.instance
      @listeners = []
    end

    def add_permanent_listeners
      listen_property_changed
      listen_new_connection
      listen_connection_deleted
      listen_current_connections
    end

    def listen
      @thread = Thread.new { @loop.run }
    end

    def quit
      @thread.exit
    end

    private

    def listen_property_changed
      @nm_i.on_signal('PropertiesChanged') do |props|
        props.each do |key, value|
          case key.to_sym
          when :State
            handle_state_change(value)
          when :Connectivity
            handle_connectivity_change(value)
          when :ActivatingConnection
            StateCache.connection_attempt = true
          when :ActiveConnections
            value.each { |ac_path| handle_ac_change(ac_path) }
          when :PrimaryConnection
            StateCache.update_primary_connection(value)
          else
            Rails.logger.info "unhandled property name #{key} in #{__method__}"
          end
        end
      rescue StandardError => e
        Rails.logger.error "#{__method__} #{e.message}"
      end
    end

    def listen_new_connection
      @nm_settings_i.on_signal('NewConnection') do |connection_path|
        persist_inactive_connection(settings_path: connection_path)
      rescue StandardError => e
        Rails.logger.error "#{__method__} #{e.message}"
      end
    end

    def listen_connection_deleted
      @nm_settings_i.on_signal('ConnectionRemoved') do |connection_path|
        NmNetwork.find_by(connection_settings_path: connection_path).destroy
      rescue StandardError => e
        Rails.logger.error "#{__method__} #{e.message}"
      end
    end

    def listen_current_connections
      @nm_i['ActiveConnections'].each { |ac_path| add_connection_listener(ac_path) }
    end

    def add_connection_listener(ac_path)
      return if @listeners.include?(ac_path)

      ac_if = @nm_s[ac_path][NmInterfaces::CONNECTION_ACTIVE]
      ac_if.on_signal('PropertiesChanged') do |props|
        handle_connection_props_change(ac_path: ac_path, props: props)
      rescue StandardError => e
        Rails.logger.error "#{__method__} #{e.message} #{ac_path}"
        NmNetwork.find_by(active_connection_path: ac_path)&.deactivate
      ensure
        StateCache.refresh_networks
      end
      @listeners << ac_path
    end

    def handle_state_change(nm_state)
      StateCache.online = System.state_is_online?(nm_state)
      case nm_state
      when NmState::UNKNOWN..NmState::DISCONNECTED
        SettingExecution::Network.schedule_ap
      when NmState::CONNECTING..NmState::CONNECTED_GLOBAL
        SettingExecution::Network.cancel_ap_schedule
      else
        Rails.logger.debug "unhandled state change #{nm_state}"
      end
    end

    # React to changes in NetworkManager's overall connectivity state.
    # @param [Integer] connectivity_state Integer describing NetworkManager's overall connectivity state.
    # @return [nil]
    def handle_connectivity_change(connectivity_state)
      # TODO: Pass through state to clients once implemented there
      StateCache.connectivity = connectivity_state
    end

    # @param [String] ac_path DBus object path to an active connection.
    def handle_ac_change(ac_path)
      attempts = 0
      begin
        ac_if = @nm_s[ac_path][NmInterfaces::CONNECTION_ACTIVE]
        case ac_if['State']
        when NmActiveConnectionState::ACTIVATING..NmActiveConnectionState::ACTIVATED
          add_connection_listener(ac_path)
          # Connection listener might not be set up fast enough, persist network here.
          sleep 0.25 until ac_if['State'].eql?(NmActiveConnectionState::ACTIVATED)
          persist_active_connection(object_path: ac_path, iface: ac_if)
        when NmActiveConnectionState::DEACTIVATING..NmActiveConnectionState::DEACTIVATED
          @listeners.delete(ac_path)
          NmNetwork.find_by(active_connection_path: ac_path)&.deactivate
        else
          Rails.logger.warn "new connection with unhandled state: #{ac_if['Id']} #{ac_if['State']}"
        end
      rescue StandardError => e
        Rails.logger.warn "#{__method__} #{ac_path}: #{e.message}"
        sleep 1
        retry if (attempts += 1) <= 3
      end
    end

    def handle_connection_props_change(ac_path:, props:)
      props.each do |key, value|
        case key.to_sym
        when :State
          change_connection_active_state(ac_path: ac_path, state: value)
        when :Ip4Config
          update_connection_ip_address(
            ac_path: ac_path,
            protocol_version: IP4_PROTOCOL,
            ip_config_path: value
          )
        when :Ip6Config
          update_connection_ip_address(
            ac_path: ac_path,
            protocol_version: IP6_PROTOCOL,
            ip_config_path: value
          )
        else
          Rails.logger.debug "unhandled property name #{key} in #{__method__}"
        end
      end
    end

    def retry_wrap(&block)
      attempts = 0
      begin
        block
      end
    rescue StandardError => e
      Rails.logger.warn "#{__method__} #{e.message}"
      sleep 1
      retry if (attempts += 1) <= 5

      raise e
    end
  end
end
