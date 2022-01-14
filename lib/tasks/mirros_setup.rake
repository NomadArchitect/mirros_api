# frozen_string_literal: true

require 'os'
require 'dbus'

namespace :mirros do
  namespace :setup do
    desc 'Set up static network connections for LAN and Setup WiFi'
    task network_connections: :environment do
      next unless OS.linux?

      NetworkManager::Bus.new.add_predefined_connections
    end

    desc 'Remove static network connections for LAN and Setup WiFi'
    task remove_network_connections: :environment do
      if OS.linux?
        bus = NetworkManager::Bus.new
        bus.delete_connection('glancrsetup')
        bus.delete_connection('glancrlan')
      end
    end
  end
end
