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
  validates :styles, store_model: { merge_errors: true }
  after_commit :update_board

  # Updates the parent board to ensure the new instance is included in relationships.
  # @return [TrueClass]
  def update_board
    board.save
  end
end
