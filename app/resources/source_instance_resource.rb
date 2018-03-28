class SourceInstanceResource < JSONAPI::Resource
  has_one :source
  has_many :widget_instances, through: :instance_associations
end
