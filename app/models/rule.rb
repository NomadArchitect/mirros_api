# frozen_string_literal: true

# Model that holds a single rule which is as part of a board's rule set.
class Rule < ApplicationRecord
  include ActiveModel::Validations

  attr_reader :operator_class

  belongs_to :board
  belongs_to :source_instance, optional: true

  before_validation :setup
  after_validation :normalize_timestamp, if: -> { errors.blank? && operator.eql?('betweenDates') }

  after_commit :refresh_board_schedule

  validates_exclusion_of :board_id,
                         in: ->(_rule) { [Board.first.id] },
                         message: I18n.t('rule.errors.messages.no_default_board')
  validates_each :value do |record, attr, value|
    record.operator_class.parse(value)
  rescue StandardError => e
    record.errors.add attr, "Value #{value} incompatible with #{@operator_class} operator: #{e.message}"
  end

  # Evaluates this rule through the associated operator.
  # @return [TrueClass, FalseClass] Whether the rule applies or not.
  def evaluate
    setup
    # TODO: Remove parse call if we implement typecasting before save
    @operator_class.evaluate @provider_class.method(field.underscore).call, @operator_class.parse(value)
  end

  def setup
    @provider_class = "RuleManager::#{provider.camelize}RulesProvider".safe_constantize
    raise ArgumentError, "Failed to instantiate RuleManager::#{provider.camelize}RulesProvider" if @provider_class.nil?

    @operator_class = @provider_class.rules.dig(field.to_sym, :operators, operator.to_sym)
    raise ArgumentError, "Failed to instantiate RuleManager::Operators::#{operator.camelize}" if @operator_class.nil?
  end

  def normalize_timestamp
    normalized = ->(value) { Time.zone.parse(value).utc.iso8601 }
    tz = Setting.value_for(:system_timezone)
    Time.zone = tz unless tz.nil?
    self.value = { start: normalized.call(value['start']), end: normalized.call(value['end']) }
  end

  # Calls the board scheduler to determine which job to run.
  #
  # @return [Hash] The (un)scheduled configuration.
  def refresh_board_schedule
    RuleManager::Scheduler.init_jobs rotation_enabled: System.board_rotation_enabled?
  end
end
