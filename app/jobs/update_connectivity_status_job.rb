# frozen_string_literal: true

# Updates the connectivity state
class UpdateConnectivityStatusJob < ApplicationJob
  queue_as :system

  def perform(check_via_dns: false)
    if check_via_dns
      StateCache.put :connectivity, StateCache.connectivity_from_dns
    else
      return unless OS.linux? && NetworkManager::Commands.instance.connectivity_check_available?

      StateCache.put :connectivity, NetworkManager::Commands.instance.connectivity
    end
  end
end
