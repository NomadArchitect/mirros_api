class SourceInstanceResource < JSONAPI::Resource
  attributes :title, :configuration, :options, :last_refresh

  has_one :source, exclude_links: [:self]
  has_many :widget_instances,
           through: :instance_associations,
           always_include_linkage_data: true,
           exclude_links: [:self]
  has_many :record_links, always_include_linkage_data: true, exclude_links: [:self]

end
