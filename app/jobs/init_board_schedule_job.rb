# One-time job to schedule the Board rules, depending on current configuration.
class InitBoardScheduleJob < ApplicationJob
  queue_as :system

  def perform(*args)
    RuleManager::Scheduler.init_jobs rotation_enabled: System.board_rotation_enabled?
  end
end
