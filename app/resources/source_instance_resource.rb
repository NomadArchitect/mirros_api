class SourceInstanceResource < JSONAPI::Resource
  attributes :title, :configuration
  has_one :source
  has_many :widget_instances, through: :instance_associations
end
