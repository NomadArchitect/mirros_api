# frozen_string_literal: true
require 'os'
require 'dbus'

namespace :mirros do
  namespace :setup do
    desc 'Set up static network connections for LAN and Setup WiFi'
    task network_connections: :environment do
      NetworkManager::Commands.instance.add_predefined_connections if OS.linux?
    end
  end
end
