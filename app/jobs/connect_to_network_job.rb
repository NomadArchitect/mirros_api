class ConnectToNetworkJob < ApplicationJob
  queue_as :system

  def perform(*_args)
    SettingExecution::Network.connect
  end
end
