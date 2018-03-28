class SourceInstance < Instance
  belongs_to :source
  has_many :instance_associations
  has_many :widget_instances, through: :instance_associations
end
