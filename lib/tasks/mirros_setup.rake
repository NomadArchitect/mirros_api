# frozen_string_literal: true
require 'os'
require 'dbus'

namespace :mirros do
  namespace :setup do
    desc 'Set up static network connections for LAN and Setup WiFi'
    task network_connections: :environment do
      NetworkManager::Commands.instance.add_predefined_connections if OS.linux?

    desc 'Creates NmNetwork records for existing NetworkManager connections. Intended as a one-time job for the update 1.0.2 -> 1.0.3'
    task delete_connections_without_model: :environment do
      next unless OS.linux?

      predefined = %w[glancrsetup glancrlan]
      next if NmNetwork.where(connection_id: predefined).length.eql? 2

      nm_s = DBus.system_bus['org.freedesktop.NetworkManager']
      nm_s_o = nm_s['/org/freedesktop/NetworkManager/Settings']
      nm_s_i = nm_s_o['org.freedesktop.NetworkManager.Settings']
      # noinspection RubyResolve
      nm_s_i.ListConnections.each do |con|
        nm_s = DBus.system_bus['org.freedesktop.NetworkManager']
        nm_conn_o = nm_s[con]
        nm_conn_i = nm_conn_o['org.freedesktop.NetworkManager.Settings.Connection']
        # noinspection RubyResolve
        settings = nm_conn_i.GetSettings
        nm_conn_i.Delete if predefined.include?(settings['connection']['id'])
      end
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
