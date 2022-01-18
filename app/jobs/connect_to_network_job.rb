class ConnectToNetworkJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    SettingExecution::Network.connect
  end
end
