class UpdatePrimaryConnectionJob < ApplicationJob
  queue_as :system

  def perform(ac_path)
    StateCache.put :primary_connection,
                   NmNetwork.find_by(active_connection_path: ac_path)&.public_info
  end
end
