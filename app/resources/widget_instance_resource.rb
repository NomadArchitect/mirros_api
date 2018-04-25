class WidgetInstanceResource < JSONAPI::Resource
  attributes :configuration
  has_one :widget
  has_many :instance_associations
  has_many :source_instances, through: :instance_associations
end
