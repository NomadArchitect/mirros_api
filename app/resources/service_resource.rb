class ServiceResource < JSONAPI::Resource
  attributes :status, :parameters
  has_one :provider,
          class_name: 'Widget',
          foreign_key: 'id',
          always_include_linkage_data: true
end
