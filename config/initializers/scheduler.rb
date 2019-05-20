#
# config/initializers/scheduler.rb

require 'rufus-scheduler'
require 'yaml'

# only schedule when not running from the Ruby on Rails console or from a rake task
if Rails.const_defined? 'Server'
  # Initialize session
  settings_cache = SettingsCache.singleton
  state_cache = StateCache.singleton

  if OS.linux?
    SettingExecution::Network.disable_lan unless settings_cache[:network_connectiontype].eql? 'lan'
  end

  s = Rufus::Scheduler.singleton(lockfile: "#{Rails.root}/tmp/.rufus-scheduler.lock")
  s.stderr = File.open("#{Rails.root}/log/scheduler.log", 'wb')

  MirrOSApi::DataRefresher.schedule_all

  # Perform initial network status check if required and schedule consecutive checking.
  System.check_network_status unless state_cache.current_ip.present?

  s.every '30s', tag: 'network-status-check', overlap: false do
    System.check_network_status
  end

  if SettingsCache.s[:network_connectiontype].eql?('wlan')
    s.every '2m', tag: 'network-signal-check', overlap: false do
      StateCache.s.network_status = SettingExecution::Network.check_signal
    end
  end
end
