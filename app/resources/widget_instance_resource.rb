class WidgetInstanceResource < JSONAPI::Resource
  has_one :widget
  has_many :source_instances, through: :instance_associations
end
