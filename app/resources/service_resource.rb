class ServiceResource < JSONAPI::Resource
  attributes :status, :parameters
  has_one :widget,
          always_include_linkage_data: true
end
