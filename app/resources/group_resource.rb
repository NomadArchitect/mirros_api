class GroupResource < JSONAPI::Resource
  attributes :name
  has_many :widgets, always_include_linkage_data: true
  has_many :sources, always_include_linkage_data: true
end
