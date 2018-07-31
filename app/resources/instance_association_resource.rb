class InstanceAssociationResource < JSONAPI::Resource
  attribute :configuration
  has_one :group
  has_one :widget_instance
  has_one :source_instance
end
