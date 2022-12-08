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

  # Store model for each widget is dynamically injected before validation.
  ModelSelector = StoreModel.one_of do |json|
    json["_model"]&.constantize || WidgetInstanceConfiguration
  end
  attribute :configuration, ModelSelector.to_type
  before_validation :configuration_default, on: :create
  validates :configuration, store_model: { merge_errors: true }, if: :configuration_changed?
  after_validation :after_validation_callback, if: :configuration_changed?

  after_commit :update_board

  private

  # Updates the parent board to ensure the new instance is included in relationships.
  # @return [TrueClass]
  def update_board
    board.save
  end

  # Overrides the style defaults if the widget specifies its own.
  def override_default_styles
    engine = widget.engine_class
    return unless engine&.const_defined?(:DEFAULT_STYLES, false)

    self.styles = engine&.const_get(:DEFAULT_STYLES)
  end

  # Set the default configuration for a new widget instance from its widget.
  def configuration_default
    model = widget.configuration_model
    if model.present? && model.ancestors.include?(WidgetInstanceConfiguration)
      self.configuration = model.new
    else
      raise RuntimeError, "Implement configuration class for #{widget.name}"
    end
  end

  # Allows widget to act after configuration has been validated.
  def after_validation_callback
    if configuration.respond_to? :after_validation
      configuration.after_validation
    end
  end

end
