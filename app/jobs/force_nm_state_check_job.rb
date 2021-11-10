class ForceNmStateCheckJob < ApplicationJob
  queue_as :system

  def perform(*args)
    state = NetworkManager::Commands.instance.state
    StateCache.put :nm_state, state
    StateCache.put :online, state
  end
end
