# frozen_string_literal: true

# Instance of a Widget on a board, with unique settings and associations.
# @!attribute styles
#   @return [WidgetInstanceStyles] the styles object for this WidgetInstance
class WidgetInstance < Instance
  belongs_to :widget
  belongs_to :board, inverse_of: :widget_instances
  has_one :group, through: :widget
  has_many :instance_associations, dependent: :destroy
  has_many :source_instances, through: :instance_associations

  attribute :styles, WidgetInstanceStyles.to_type, default: WidgetInstanceStyles.new
  before_create :override_default_styles
  validates :styles, store_model: { merge_errors: true }
  validate :validate_configuration, if: :configuration_changed?

  before_validation :check_license_status,
                    if: -> { persisted? && changed_attributes.key?('styles') }

  after_commit :update_board

  private

  # Updates the parent board to ensure the new instance is included in relationships.
  # @return [TrueClass]
  def update_board
    board.save
  end

  # Checks if this installation is registered and adds a RecordInvalid error if not.
  # @return [nil]
  def check_license_status
    return if RegistrationHandler.new.product_key_valid?

    errors.add('styles', 'this requires a valid product key.')
  end

  # Overrides the style defaults if the widget specifies its own.
  def override_default_styles
    engine = widget.engine_class
    return unless engine&.const_defined?(:DEFAULT_STYLES, false)

    self.styles = engine&.const_get(:DEFAULT_STYLES)
  end

  # Validates the current configuration against the widget's validator.
  def validate_configuration
    validator_class = widget.validator_class
    if validator_class.present? && validator_class.respond_to?(:validate_configuration)
      validator_class.validate_configuration configuration
    end
    rescue StandardError => e
      Rails.logger.warn "[#{__method__} #{widget_id}] #{e.message}"
      errors.add(:configuration, e.message)
  end

end
