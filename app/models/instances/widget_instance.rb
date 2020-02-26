# frozen_string_literal: true

class WidgetInstance < Instance
  belongs_to :widget
  belongs_to :board, inverse_of: :widget_instances
  has_one :group, through: :widget
  has_many :instance_associations, dependent: :destroy
  has_many :source_instances, through: :instance_associations

  after_commit :update_board

  def update_board
    board.save
  end
end
