# frozen_string_literal: true

module RuleManager
  # Dispatches rule processing and rotation interval jobs to set the active board.
  class BoardScheduler

    # Stops interval-based rotation and schedules an hourly job that evaluates current board rules.
    # The first matched rule determines the new active board.
    #
    # @return [Hash] the scheduled configuration
    def self.start_rule_evaluation
      stop_rotation_interval

      Sidekiq.set_schedule EvaluateBoardRulesJob.name,
                           {
                             interval: 1.second,
                             class: EvaluateBoardRulesJob
                           }
    end

    # Stops the rule evaluation job.
    #
    # @return [Boolean] whether the log entry succeeded.
    def self.stop_rule_evaluation
      Rails.logger.info "Removed the schedule #{Sidekiq.remove_schedule EvaluateBoardRulesJob.name}"
    end

    # Stops the rule evaluation job and starts the interval-based board rotation.
    #
    # @param interval [String]
    # @return [Hash] the scheduled configuration
    def self.start_rotation_interval(interval = nil)
      stop_rule_evaluation

      interval ||= Setting.value_for(:system_boardrotationinterval)
      Sidekiq.set_schedule RotateActiveBoardJob.name,
                           {
                             every: interval,
                             class: RotateActiveBoardJob
                           }
    end

    # Stops the rotation job.
    #
    def self.stop_rotation_interval
      config = Sidekiq.remove_schedule RotateActiveBoardJob.name
      Rails.logger.info "Removed the schedule #{config}"
    end

    def self.init_jobs(rotation_state = nil)
      if rotation_state.eql?('on') || Setting.value_for(:system_boardrotation)
        stop_rule_evaluation
        start_rotation_interval
      else
        stop_rotation_interval
        start_rule_evaluation if rule_evaluation_useful?
      end
    end

    def self.rule_evaluation_useful?
      Board.count.positive? && Rule.count.positive?
    end
  end
end
