# frozen_string_literal: true

# Model that holds a single rule which is as part of a board's rule set.
class Rule < ApplicationRecord
  include ActiveModel::Validations

  attr_reader :operator_class

  belongs_to :board
  belongs_to :source_instance, optional: true

  before_validation :setup
  validates_each :value do |record, attr, value|
    record.operator_class.parse(value)
  rescue StandardError => e
    record.errors.add attr, "Value #{value} incompatible with #{@operator_class} operator: #{e.message}"
  end

  def evaluate
    setup
    # TODO: Remove parse call if we implement typecasting before save
    @operator_class.evaluate @provider_class.method(field.underscore).call, @operator_class.parse(value)
  end

  def setup
    @provider_class = "RuleManager::#{provider.camelize}RulesProvider".safe_constantize
    raise ArgumentError, "Failed to instantiate RuleManager::#{provider.camelize}RulesProvider" if @provider_class.nil?

    @operator_class = @provider_class.rules.dig(field.to_sym, :operators, operator.to_sym)
  end
end
