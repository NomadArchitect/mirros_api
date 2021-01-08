# frozen_string_literal: true

# Error class for InstanceAssociation configuration errors.
class SourceInstanceArgumentError < StandardError
  attr_reader :field

  # @param [String] field The InstanceAssociation field that caused the error.
  # @param [String|nil] msg The error message
  def initialize(field, msg = nil)
    @field = field
    super(msg)
  end
end
