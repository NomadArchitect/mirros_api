# frozen_string_literal: true

require 'rufus-scheduler'
require 'yaml'

# only schedule when not running from the Ruby on Rails console or from a rake task
if Rails.const_defined? 'Server'
  # Initialize session
  settings_cache = SettingsCache.singleton
  state_cache = StateCache.singleton

  s = Rufus::Scheduler.singleton(lockfile: Rails.root.join('tmp', '.rufus-scheduler.lock'))
  s.stderr = File.open(Rails.root.join('log', 'scheduler.log'), 'wb')

  # Perform initial network status check if required and schedule consecutive checking.
  System.check_network_status if state_cache.current_ip.blank?

  s.every '30s', tag: 'network-status-check', overlap: false do
    System.check_network_status
    ActionCable.server.broadcast 'status', payload: System.info
  end

  if SettingsCache.s[:network_connectiontype].eql?('wlan')
    s.every '2m', tag: 'network-signal-check', overlap: false do
      StateCache.s.network_status = SettingExecution::Network.check_signal
      ActionCable.server.broadcast 'status', payload: System.info
    end
  end

  # FIXME: Ubuntu Core keeps losing system timezone settings. This ensures the
  # proper timezone is set at all times. Remove once https://bugs.launchpad.net/snappy/+bug/1650688
  # is resolved.
  if ENV['SNAP_VERSION']
    tz = SettingsCache.s[:system_timezone]
    SettingExecution::System.timezone(tz) unless tz.empty?

    s.every '30m', tag: 'system-fix-system-timezone', overlap: false do
      tz = SettingsCache.s[:system_timezone]
      SettingExecution::System.timezone(tz) unless tz.empty?
    end
  end

  # Required to run in separate thread because scheduler triggers ActionCable, which is not fully up until here
  Thread.new do
    sleep 15
    DataRefresher.schedule_all
    ActiveRecord::Base.connection.close
  end
end
