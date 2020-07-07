# frozen_string_literal: true

module RuleManager
  class BoardScheduler
    RULE_EVALUATION_TAG = 'system-board-rule-evaluation'
    ROTATION_INTERVAL_TAG = 'system-board-rotation'

    # Schedules an hourly job that evaluates current board rules.
    # The first matched rule determines the new active board.
    #
    # @return [Boolean] returns the log entry status, which assumes all went well
    def self.start_rule_evaluation
      return if job_running? RULE_EVALUATION_TAG

      Rufus::Scheduler.singleton.cron '0 * * * *', tag: RULE_EVALUATION_TAG do
        Board.all.each do |board|
          # TODO: Extend logic for rule sets in each board.
          # Right now, this only gets time-based rules for the board and runs them in sequential order.
          if board.rules.where(provider: 'system', field: 'timeOfDay').any?(&:evaluate)
            Setting.find_by(slug: :system_activeboard).update(value: board.id)
            break
          end
        end
      end
      Rails.logger.info "scheduled job #{RULE_EVALUATION_TAG}"
    end

    # Stops the rule evaluation job.
    #
    # @return [Boolean] whether the log entry succeeded.
    def self.stop_rule_evaluation
      return unless job_running? RULE_EVALUATION_TAG

      Rufus::Scheduler.s.cron_jobs(tag: RULE_EVALUATION_TAG).each(&:unschedule)
      Rails.logger.info "stopped job #{RULE_EVALUATION_TAG}"
    end

    # Starts the board rotation job.
    #
    # @param interval [String]
    # @return [Boolean] whether the log entry succeeded.
    def self.start_rotation_interval(interval = nil)
      return if job_running? ROTATION_INTERVAL_TAG

      parsed = Rufus::Scheduler.parse(interval || SettingsCache.s[:system_boardrotationinterval])
      Rufus::Scheduler.singleton.every parsed, tag: ROTATION_INTERVAL_TAG do
        active_board_setting = Setting.find_by(slug: :system_activeboard)
        boards = Board.ids
        new_board_id = boards[boards.find_index(active_board_setting.value.to_i) + 1] || boards.first
        active_board_setting.update(value: new_board_id)
      end
      Rails.logger.info "scheduled job #{ROTATION_INTERVAL_TAG} every #{parsed} seconds"
    rescue ArgumentError => e
      Rails.logger.error "failed to start rotation job: #{e.message}"
    end

    # Stops the rotation job.
    #
    # @return [Boolean] whether the log entry succeeded.
    def self.stop_rotation_interval
      return unless job_running? ROTATION_INTERVAL_TAG

      Rufus::Scheduler.s.every_jobs(tag: ROTATION_INTERVAL_TAG).each(&:unschedule)
      Rails.logger.info "stopped job #{ROTATION_INTERVAL_TAG}"
    end

    def self.manage_jobs(rotation_active: false)
      if rotation_active
        stop_rule_evaluation
        start_rotation_interval
      else
        stop_rotation_interval
        start_rule_evaluation
      end
    end

    def self.job_running?(tag)
      Rufus::Scheduler.singleton.jobs(tag: tag).present?
    end
  end
end
