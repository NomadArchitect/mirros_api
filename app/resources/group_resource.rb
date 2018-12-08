class GroupResource < JSONAPI::Resource
  caching

  primary_key :slug
  key_type :string

  attributes :name
  has_many :widgets, always_include_linkage_data: true
  has_many :sources, always_include_linkage_data: true
end
