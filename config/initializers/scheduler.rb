# frozen_string_literal: true

require 'rufus-scheduler'
require 'yaml'

# Prevent scheduling for Rails console starts or rake tasks.
if Rails.const_defined? 'Server'
  s = Rufus::Scheduler.singleton(
    lockfile: Rails.root.join('tmp/.rufus-scheduler.lock')
  )
  s.stderr = File.open(Rails.root.join('log/scheduler.log'), 'wb')

  # Reset StateCache so everything has the latest values.
  StateCache.refresh

  if OS.linux?
    # On linux hosts, we utilize NetworkManager signal listeners.
    listeners = NetworkManager::SignalListeners.instance
    listeners.add_permanent_listeners
    listeners.listen

    at_exit { listeners.quit }

    # As of N-M 1.10, the connectivity status doesn't seem to be pushed reliably
    # over DBus. This ensures the StateCache is updated at least every minute.
    # TODO: Revisit once we can use 1.16 or later on Core.
    if NetworkManager::Commands.instance.connectivity_check_available?
      s.every '60s', tag: 'network-connectivity-check', overlap: false do
        StateCache.put :connectivity, NetworkManager::Commands.instance.connectivity
      end
    end
  else
    # On other hosts, we schedule network status check jobs.
    s.every '30s', tag: 'network-status-check', overlap: false do
      System.check_network_status
      System.push_status_update
    end
  end

  # TODO: Move this to NetworkManager SignalListeners once we figure out a reliable
  # way to have only one listener for the active access point. ruby-dbus doesn't
  # seem to allow removing listeners, but the AP might still be active in NM.
  s.every '2m', tag: 'network-signal-check', overlap: false do
    next unless System.using_wifi?

    StateCache.put :network_status, SettingExecution::Network.wifi_signal_status
  end

  if ENV['SNAP']
    # FIXME: Ubuntu Core may loose timezone settings after reboot. Force a reset at startup.
    # Remove once https://bugs.launchpad.net/snappy/+bug/1650688 is resolved.
    System.reset_timezone
  end

  # Perform initial network status to determine if we need the AP right away
  System.check_network_status
  SettingExecution::Network.open_ap unless System.no_offline_mode_required?

  # Separate thread because scheduler triggers ActionCable, which is not fully up at this point.
  Thread.new do
    sleep 10 # Ensure ActionCable is running.

    if System.setup_completed? # Prevent scheduling before setup is finished.
      System.schedule_welcome_mail
      System.schedule_defaults_creation
    end

    SourceInstance.all.each do |source_instance|
      source_instance.schedule
      sleep 5 # avoid parallel refreshes when called on multiple instances.
    end
    RuleManager::BoardScheduler.manage_jobs(
      rotation_active: Setting.value_for(:system_boardrotation).eql?('on')
    )
  end
end
