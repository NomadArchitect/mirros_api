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
      @nm_o = @nm_s[ObjectPaths::NETWORK_MANAGER]
      @nm_i = @nm_o[NmInterfaces::NETWORK_MANAGER]
      @nm_settings_i = @nm_s[ObjectPaths::NM_SETTINGS][NmInterfaces::SETTINGS]
      @listeners = []
      @loop = nil
      @listening = false
      @listener_thread = nil
    end

    def add_permanent_listeners
      listen_current_connections
      listen_property_changed
      listen_new_connection
      listen_connection_deleted
    end

    def listen
      return if listening?

      @loop = DBus::Main.new
      @loop << DBus::SystemBus.instance
      @listener_thread = Thread.new do
        Logger.debug 'running loop …'
        @loop.run
      ensure
        @loop.quit
        Logger.debug 'stopped loop'
      end
      @listening = true
      Logger.debug "listening in #{@listener_thread}, status: #{@listening}"
    end

    def quit
      return unless listening?

      Logger.debug "Quitting listener #{@listener_thread}, status: #{@listening}"
      @listener_thread.exit
      Logger.debug "Killed process #{@listener_thread}"
      @listening = false
      Logger.debug "New listening status: #{@listening}"
    end

    def listening?
      @listening
    end

    def restart
      Logger.debug "Called #{__method__}, listen status: #{listening?}"
      return unless listening?

      Logger.debug 'Restarting listener'
      quit
      add_permanent_listeners
      listen
    rescue StandardError => e
      Logger.error e.message
      raise e
    end

    private

    def listen_property_changed
      @nm_i.on_signal('PropertiesChanged') do |props|
        # Logger.debug "NM props changed: #{props}"
        props.each do |key, value|
          case key.to_sym
          when :State
            handle_state_change(value)
          when :Connectivity
            handle_connectivity_change(value)
          when :ActivatingConnection
            StateCache.connection_attempt = true unless value.eql?('/')
          when :ActiveConnections
            value.each { |ac_path| handle_ac_change(ac_path) }
          when :PrimaryConnection
            StateCache.connection_attempt = false
            StateCache.update_primary_connection(value)
          else
            # Rails.logger.info "unhandled property name #{key} in #{__method__}"
          end
        end
      rescue StandardError => e
        Logger.error "#{__method__} #{e.backtrace} #{e.message}"
      end
    end

    def listen_new_connection
      Logger.debug 'Adding NewConnection listener'
      @nm_settings_i.on_signal('NewConnection') do |connection_path|
        persist_inactive_connection(settings_path: connection_path)
      rescue StandardError => e
        Logger.error "#{__method__} #{e.message}"
      end
    end

    def listen_connection_deleted
      Logger.debug 'Adding ConnectionRemoved listener'
      @nm_settings_i.on_signal('ConnectionRemoved') do |connection_path|
        ActiveRecord::Base.connection.verify!(0) unless ActiveRecord::Base.connected?
        NmNetwork.find_by(connection_settings_path: connection_path)&.destroy
      rescue StandardError => e
        Logger.error "#{__method__} #{e.message}"
      ensure
        ActiveRecord::Base.clear_active_connections!
      end
    end

    def listen_current_connections
      @nm_i['ActiveConnections'].each { |ac_path| listen_active_connection(ac_path) }
    end

    def listen_active_connection(ac_path)
      return if @listeners.include?(ac_path)

      Logger.debug "#{ac_path} not present in #{@listeners}, adding"
      @listeners.push ac_path
      ac_if = @nm_s[ac_path][NmInterfaces::CONNECTION_ACTIVE]
      ac_if.on_signal('PropertiesChanged') do |props|
        ActiveRecord::Base.connection.verify!(0) unless ActiveRecord::Base.connected?
        # Logger.debug "reacting to props change on #{ac_path}"
        handle_connection_props_change(ac_path: ac_path, props: props)
      rescue StandardError => e
        # Connection going down, interface no longer available
        Logger.warn "#{ac_path} probably going down: #{e.message}"
        deactivate_network_by_ac_path(ac_path)
      ensure
        StateCache.refresh_networks
        ActiveRecord::Base.clear_active_connections!
      end
    rescue StandardError => e
      Logger.error "#{__method__} L:#{__LINE__} #{e.message}"
      # deactivate_network_by_ac_path(ac_path)
    end

    # Assumes that the Access Point does not change for the given SSID.
    def listen_ap_signal
      return if ap_listener_active?

      pc_path = @nm_i['PrimaryConnection']
      pc_if = @nm_s[pc_path][NmInterfaces::CONNECTION_ACTIVE]
      ap_path = pc_if['SpecificObject']
      Logger.debug "Adding listener for #{pc_path}, specificObj: #{ap_path}"
      return if ap_path.eql?('/')

      ap_if = @nm_s[ap_path][NmInterfaces::ACCESS_POINT]
      ap_if.on_signal('PropertiesChanged') do |props|
        handle_ap_props_change(ap_if: ap_if, props: props)
      end
    rescue DBus::Error => e
      Logger.warn e.message
    end

    def handle_state_change(nm_state)
      StateCache.update_online_status(nm_state)
      case nm_state
      when NmState::UNKNOWN..NmState::DISCONNECTED
        SettingExecution::Network.schedule_ap
      when NmState::CONNECTING..NmState::CONNECTED_GLOBAL
        SettingExecution::Network.cancel_ap_schedule
      else
        # Rails.logger.debug "unhandled state change #{nm_state}"
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
      # Logger.debug "reacting to ActiveConnections change for #{ac_path}"
      ac_if = @nm_s[ac_path][NmInterfaces::CONNECTION_ACTIVE]
      case ac_if['State']
      when NmActiveConnectionState::ACTIVATING..NmActiveConnectionState::ACTIVATED
        listen_active_connection(ac_path)
        Logger.debug "#{__method__} #{ac_path} is activating or activated, added listener"
      when NmActiveConnectionState::DEACTIVATING..NmActiveConnectionState::DEACTIVATED
        @listeners.delete(ac_path)
        Logger.debug "#{ac_path} deactivating, deleted from listeners: #{@listeners}"
      else
        Logger.debug "active connection #{ac_path} with unhandled state #{ac_if['State']}"
      end
    rescue DBus::Error => e
      @listeners.delete(ac_path)
      Logger.error "#{__method__} deleted #{ac_path} from listeners as we couldn't get its state: #{e.message}"
    end

    def handle_connection_props_change(ac_path:, props:)
      props.each do |key, value|
        # Logger.debug "#{__method__} prop change for #{ac_path} #{key} #{value}"
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
          # Logger.debug "unhandled property #{key} in #{__method__}"
        end
      rescue DBus::Error, ActiveRecordError => e
        Logger.error "#{__method__} #{e.message}"
        Logger.warn "#{__method__} destroying model with #{NmNetwork.find_by(active_connection_path: ac_path)&.connection_id}"
        # Connection probably deleted, so we should delete the corresponding model.
        NmNetwork.find_by(active_connection_path: ac_path)&.destroy
      end
    end

    def handle_ap_props_change(ap_if:, props:)
      props.each do |key, value|
        if key.eql?('Strength')
          StateCache.network_status = {
            ssid: ap_if['Ssid'].pack('U*'), signal: value.to_i
          }
        end
      rescue DBus::Error => e
        Rails.logger.error e.message
        StateCache.network_status = { ssid: nil, signal: nil }
      end
    end

    def deactivate_network_by_ac_path(ac_path:)
      NmNetwork.find_by(active_connection_path: ac_path)&.deactivate
      @listeners.delete ac_path
    end
  end
end
