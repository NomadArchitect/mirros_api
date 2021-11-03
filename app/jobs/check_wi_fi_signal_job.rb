class CheckWiFiSignalJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    return unless System.using_wifi?

    # TODO: Move this to NetworkManager SignalListeners once we figure out a reliable
    # way to have only one listener for the active access point. ruby-dbus doesn't
    # seem to allow removing listeners, but the AP might still be active in NM.
    StateCache.put :network_status, SettingExecution::Network.wifi_signal_status
  end
end
