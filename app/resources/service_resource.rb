class ServiceResource < JSONAPI::Resource
  attributes :status, :parameters
  has_one :widget
end
