class BoardResource < JSONAPI::Resource
  attributes :title

  has_many :widget_instances,
           always_include_linkage_data: true,
           exclude_links: [:self]
end
