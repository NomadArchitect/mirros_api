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
      @nm_service = DBus.system_bus['org.freedesktop.NetworkManager']
      @nm_iface = @nm_service[ObjectPaths::NETWORK_MANAGER][NmInterfaces::NETWORK_MANAGER]
      @nm_settings_iface = @nm_service[ObjectPaths::NM_SETTINGS][NmInterfaces::SETTINGS]
      @loop = nil
      @listening = false
      @listener_thread = nil
    end

    def add_permanent_listeners
      listen_property_changed
      listen_for_connection_changes
    end

    def listen
      return if listening?

      @loop = DBus::Main.new
      @loop << DBus::SystemBus.instance
      @listener_thread = Thread.new do
        unless ActiveRecord::Base.connected?
          ActiveRecord::Base.connection.verify!(0)
        end
        Logger.debug 'running loop …'
        @loop.run
      ensure
        @loop.quit
        ActiveRecord::Base.clear_active_connections!
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

      quit
      add_permanent_listeners
      listen
    rescue StandardError => e
      Logger.error e.message
      raise e
    end

    private

    def listen_property_changed
      @nm_iface.on_signal('PropertiesChanged') do |props|
        retry_wrap max_attempts: 3 do
          props.each do |key, value|
            Logger.debug "Handling NM PropertiesChanged for #{key} with #{value}"
            case key.to_sym
            when :State
              handle_state_change(value)
            when :Connectivity
              handle_connectivity_change(value)
            when :PrimaryConnection
              Logger.debug "PrimaryConnection update: #{value}"
              StateCache.put :primary_connection, NetworkManager::Commands.instance.model_for_active_connection(value)
            else
              # Rails.logger.info "unhandled property name #{key} in #{__method__}"
            end
          end
        rescue StandardError => e
          Logger.error "#{__method__} #{e.backtrace} #{e.message}"
        end
      end
    end

    def listen_for_connection_changes
      @nm_settings_iface.on_signal('NewConnection') do |connection_path|
        settings = NetworkManager::Commands.instance.settings_for_connection_path connection_path
        NetworkManager::Cache.store_network settings['connection']['id'], settings['connection']['uuid']
      rescue StandardError => e
        Logger.error "#{__method__} #{e.message}"
      end

      @nm_settings_iface.on_signal('ConnectionRemoved') do |_connection_path|
        NetworkManager::Cache.remove_all_networks
      rescue StandardError => e
        Logger.error "#{__method__} #{e.message}"
      end
    end


    def handle_state_change(nm_state)
      Logger.debug "NmState update: #{map_state(nm_state)}"
      if nm_state.between?(NmState::UNKNOWN, NmState::DISCONNECTED)
        SettingExecution::Network.schedule_ap
      else
        SettingExecution::Network.cancel_ap_schedule
      end
      StateCache.put :nm_state, nm_state
      StateCache.put :online, nm_state
    end

    # React to changes in NetworkManager's overall connectivity state.
    # @param [Integer] connectivity_state Integer describing NetworkManager's overall connectivity state.
    # @return [nil]
    def handle_connectivity_change(connectivity_state)
      Logger.debug "Connectivity update: #{map_connectivity(connectivity_state)}"
      StateCache.put :connectivity, connectivity_state
    end
  end
end
