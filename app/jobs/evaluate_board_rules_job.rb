class EvaluateBoardRulesJob < ApplicationJob
  queue_as :system

  def perform(*args)
    # Do something later
    rule_applied = false
    Board.all.each do |board|
      # TODO: Extend logic for rule sets in each board.

      # Date-based rules take precedence over recurring rules.
      if board.rules.where(provider: 'system', field: 'dateAndTime').any?(&:evaluate)
        Setting.find_by(slug: :system_activeboard).update(value: board.id)
        rule_applied = true
        break
      end
      # TODO: this only gets time-based rules for the board and runs them in sequential order.
      if board.rules.where(provider: 'system', field: 'timeOfDay').any?(&:evaluate)
        Setting.find_by(slug: :system_activeboard).update(value: board.id)
        rule_applied = true
        break
      end
    end

    Setting.find_by(slug: :system_activeboard).update(value: Board.first.id) unless rule_applied
  end
end
