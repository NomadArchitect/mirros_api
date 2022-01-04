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
      @nm_props_iface = @nm_service[ObjectPaths::NETWORK_MANAGER][NmInterfaces::PROPERTIES]
      @nm_settings_iface = @nm_service[ObjectPaths::NM_SETTINGS][NmInterfaces::SETTINGS]
      @loop = nil
      @listening = false
      @listener_thread = nil
    end

    def add_permanent_listeners
      listen_property_changed
      listen_for_connection_changes
      listen_ap_connection
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
    end

    def quit
      return unless listening?

      @listener_thread.exit
      Logger.debug "Killed process #{@listener_thread}"
      @listening = false
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

    # TODO: Listen on AP connection for instant property change notifications

    # Listen to the PropertiesChanged signal of the NetworkManager properties interface.
    def listen_property_changed
      # NetworkManager 1.22 does not expose a PropertiesChanged signal on the NM interface.
      # We use the standard org.freedesktop.DBus.Properties interface and only act on property changes of the NM interface.
      # @see https://developer-old.gnome.org/NetworkManager/1.22/gdbus-org.freedesktop.NetworkManager.html#gdbus-signal-org-freedesktop-NetworkManager.PropertiesChanged
      @nm_props_iface.on_signal('PropertiesChanged') do |iface, props, _arr|
        return unless iface.eql?(NmInterfaces::NETWORK_MANAGER)

        retry_wrap max_attempts: 3 do
          props.each do |key, value|
            case key.to_sym
            when :State
              handle_state_change(value)
              ::System.push_status_update
            when :Connectivity
              ::System.push_status_update
              # handle_connectivity_change(value)
            when :PrimaryConnection
              ::System.push_status_update
              # Logger.debug "PrimaryConnection update: #{value}"
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
        settings = NetworkManager::Bus.new.settings_for_connection_path connection_path
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

    def listen_ap_connection
      bus = Bus.new
      bus.connection_object_path(connection_id: 'glancrsetup')
      # TODO: We want to listen on the active connection, but this only exists once the connection is ... active?
    end

    def handle_state_change(nm_state)
      if nm_state.between?(NmState::UNKNOWN, NmState::DISCONNECTED)
        SettingExecution::Network.schedule_ap
      else
        SettingExecution::Network.cancel_ap_schedule
      end
    end

    # React to changes in NetworkManager's overall connectivity state.
    # @param [Integer] connectivity_state Integer describing NetworkManager's overall connectivity state.
    # @return [nil]
    def handle_connectivity_change(connectivity_state)
      NetworkManager::Cache.write :connectivity, connectivity_state
    end
  end
end
