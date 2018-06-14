class WidgetInstanceResource < JSONAPI::Resource
  attributes :configuration, :position
  has_one :widget, always_include_linkage_data: true
  has_many :instance_associations
  has_many :source_instances, through: :instance_associations
end
