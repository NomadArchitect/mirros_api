# frozen_string_literal: true

require 'rufus-scheduler'
require 'yaml'

# Prevent scheduling for Rails console starts or rake tasks.
if Rails.const_defined? 'Server'
  s = Rufus::Scheduler.singleton(
    lockfile: Rails.root.join('tmp/.rufus-scheduler.lock')
  )
  s.stderr = File.open(Rails.root.join('log/scheduler.log'), 'wb')

  # Initialize StateCache so that signal listeners have it available
  StateCache.instance

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
        StateCache.refresh_connectivity NetworkManager::Commands.instance.connectivity
      end
    end
  else
    # On other hosts, we schedule network status check jobs.
    s.every '30s', tag: 'network-status-check', overlap: false do
      System.check_network_status
      ActionCable.server.broadcast 'status', payload: System.info
    end
  end

  # TODO: Move this to NetworkManager SignalListeners once we figure out a reliable
  # way to have only one listener for the active access point. ruby-dbus doesn't
  # seem to allow removing listeners, but the AP might still be active in NM.
  s.every '2m', tag: 'network-signal-check', overlap: false do
    next unless SettingsCache.s.using_wifi?
    unless StateCache.connectivity >= NetworkManager::Constants::NmConnectivityState::LIMITED
      next
    end

    StateCache.refresh_network_status SettingExecution::Network.wifi_signal_status
  end

  # FIXME: Ubuntu Core keeps losing system timezone settings. This ensures the
  # proper timezone is set at all times. Remove once https://bugs.launchpad.net/snappy/+bug/1650688
  # is resolved.
  if ENV['SNAP_VERSION']
    System.reset_timezone
    s.every '30m', tag: 'system-fix-system-timezone', overlap: false do
      System.reset_timezone
    end
  end

  # Perform initial network status to determine if we need the AP right away
  System.check_network_status

  # Required to run in separate thread because scheduler triggers ActionCable, which is not fully up until here
  Thread.new do
    sleep 10
    DataRefresher.run_all_once
    DataRefresher.schedule_all
    ActiveRecord::Base.connection.close

    s.cron '0 * * * *' do
      Board.all.each do |board|
        # TODO: Extend logic for rulesets in each board. Right now, this only gets time-based rules for the board and runs them in sequential order.
        if board.rules.where(provider: 'system', field: 'timeOfDay').any?(&:evaluate)
          Setting.find_by(slug: :system_activeboard).update(value: board.id)
          break
        end
      end
    end
  end
end
