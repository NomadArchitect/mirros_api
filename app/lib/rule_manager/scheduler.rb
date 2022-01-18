# frozen_string_literal: true

module RuleManager
  # Dispatches rule processing and rotation interval jobs to set the active board.
  class Scheduler

    # Schedules a job each minute that evaluates current board rules.
    # The first matched rule determines the new active board.
    #
    # @return [Hash] The scheduled configuration
    def self.start_rule_evaluation
      Sidekiq.set_schedule EvaluateBoardRulesJob.name,
                           {
                             interval: 1.minute,
                             class: EvaluateBoardRulesJob
                           }
    end

    def self.stop_rule_evaluation
      Sidekiq.remove_schedule EvaluateBoardRulesJob.name
    end

    # Starts the interval-based board rotation.
    #
    # @param interval [String]
    # @return [Hash] The scheduled configuration
    def self.start_rotation_interval(interval = nil)
      interval ||= Setting.value_for(:system_boardrotationinterval)
      Sidekiq.set_schedule RotateActiveBoardJob.name,
                           {
                             every: "#{interval.to_i}m",
                             class: RotateActiveBoardJob
                           }
    end

    def self.stop_rotation_interval
      Sidekiq.remove_schedule RotateActiveBoardJob.name
    end

    # Determines whether the rule evaluation or the board rotation job should run.
    #
    # @param [String] rotation_state  value of the system_boardrotation setting. Queries the database if omitted.
    def self.init_jobs(rotation_enabled:)
      if rotation_enabled
        stop_rule_evaluation
        start_rotation_interval
      elsif Board.count > 1 && Rule.count.positive?
        stop_rotation_interval
        start_rule_evaluation
      else
        stop_rule_evaluation
        stop_rotation_interval
      end
    end
  end
end
