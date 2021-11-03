# frozen_string_literal: true

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
