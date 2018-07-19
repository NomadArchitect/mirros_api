class WidgetInstanceResource < JSONAPI::Resource
  attributes :configuration, :position
  has_one :widget
  has_many :instance_associations, always_include_linkage_data: true
  has_many :source_instances, through: :instance_associations, always_include_linkage_data: true
end
