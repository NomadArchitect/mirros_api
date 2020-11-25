class SystemState < ApplicationRecord
  validates_uniqueness_of :variable

  # @param [String] variable A valid variable name
  # @param [String] key A key within the variable's value field.
  # @return [Object|nil] The value of the given key within value, nil if variable or key cannot be found.
  # @raise ArgumentError If the variable is valid, but the value is not an object. Use `get_value` for simple values.
  def self.dig(variable:, key:)
    find_by(variable: variable)&.value&.dig(key)
  rescue NoMethodError => e
    raise ArgumentError, "Found a SystemState entry for #{variable}, but its value is not an object. "\
                         "Use SystemState.get_value instead. Original error:\n#{e.message}"
  end
end
