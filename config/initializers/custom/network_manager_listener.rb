# frozen_string_literal: true

if OS.linux? && System.running_in_snap?
  # On linux hosts, we utilize NetworkManager signal listeners.
  listeners = NetworkManager::SignalListeners.instance
  listeners.add_permanent_listeners
  listeners.listen

  at_exit { listeners.quit }

  # As of N-M 1.10, the connectivity status doesn't seem to be pushed reliably
  # over DBus. This ensures the StateCache is updated at least every minute.
  # TODO: Revisit once we can use 1.16 or later on Core.
  Sidekiq.set_schedule UpdateConnectivityStatusJob.name,
                       {
                         interval: '30s',
                         overlap: false,
                         class: UpdateConnectivityStatusJob
                       }
end
