class OpenSetupWiFiJob < ApplicationJob
  queue_as :system

  def perform(*_args)
    SettingExecution::Network.open_ap
  end
end
