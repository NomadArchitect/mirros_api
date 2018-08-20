class WidgetInstance < Instance
  belongs_to :widget
  has_one :group, through: :widget
  has_many :instance_associations, dependent: :destroy
  has_many :source_instances, through: :instance_associations
end
