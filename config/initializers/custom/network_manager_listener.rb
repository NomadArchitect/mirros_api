# frozen_string_literal: true
return unless Rails.const_defined?('Server')

if OS.linux? && System.running_in_snap?
  # On linux hosts, we utilize NetworkManager signal listeners.
  listeners = NetworkManager::SignalListeners.instance
  listeners.add_permanent_listeners
  listeners.listen

  at_exit { listeners.quit }
end
