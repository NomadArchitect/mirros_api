# frozen_string_literal: true
require 'os'
require 'dbus'

namespace :mirros do
  namespace :setup do
    desc 'Set up static network connections for LAN and Setup WiFi'
    task network_connections: :environment do
      next unless OS.linux?

      predefined = %w[glancrsetup glancrlan]
      next if NmNetwork.where(connection_id: predefined).length.eql? 2

      NetworkManager::Commands.instance.add_predefined_connections
    end

    desc 'Remove static network connections for LAN and Setup WiFi'
    task remove_network_connections: :environment do
      # Invoking SettingExecution::Network.remove_predefined_connections would require manual inclusion
      # of command files, it's easier to replicate the task here.
      if OS.linux?
        NetworkManager::Commands.instance.delete_connection(connection_id: 'glancrsetup')
        NetworkManager::Commands.instance.delete_connection(connection_id: 'glancrlan')
      end
      NmNetwork.where(connection_id: %w[glancrlan glancrsetup]).destroy_all
    end
  end
end
