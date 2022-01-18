class ForceNmStateCheckJob < ApplicationJob
  queue_as :system

  def perform(*args)
    ::System.push_status_update
  end
end
