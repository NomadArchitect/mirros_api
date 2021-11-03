# frozen_string_literal: true

# Updates the connectivity state
class UpdateConnectivityStatusJob < ApplicationJob
  queue_as :system

  def perform(*_args)
    return unless NetworkManager::Commands.instance.connectivity_check_available?

    StateCache.put :connectivity, NetworkManager::Commands.instance.connectivity
  end
end
