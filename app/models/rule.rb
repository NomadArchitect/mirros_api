# frozen_string_literal: true

# Model that holds a single rule which is as part of a board's rule set.
class Rule < ApplicationRecord
  include ActiveModel::Validations

  attr_reader :op

  belongs_to :board
  belongs_to :source_instance, optional: true

  before_validation :setup
  validates_each :value do |record, attr, value|
    record.op.parse(value)
  rescue StandardError => e
    record.errors.add attr, "Value #{value} incompatible with #{@op} operator: #{e.message}"
  end

  def evaluate
    setup
    # TODO: Remove parse call if we implement typecasting before save
    @op.evaluate @provider_class.method(field.underscore).call, @op.parse(value)
  end

  def setup
    @provider_class = "RuleManager::#{provider.camelize}RulesProvider".safe_constantize
    raise ArgumentError, "Failed to instantiate RuleManager::#{provider.camelize}RulesProvider" if @provider_class.nil?

    @op = @provider_class.rules.dig(field.to_sym, :operators, operator.to_sym)
  end
end
