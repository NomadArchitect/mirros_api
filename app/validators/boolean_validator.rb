# frozen_string_literal: true

# Validates if the given value is a boolean.
class BooleanValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if [true, false].exclude?(value) || value.nil?
      record.errors[attribute] << (options[:message] || 'Must be true or false')
    end
  end
end
