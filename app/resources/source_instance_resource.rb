class SourceInstanceResource < JSONAPI::Resource
  attributes :title, :configuration, :options, :last_refresh

  has_one :source
  has_many :widget_instances, through: :instance_associations, always_include_linkage_data: true
  has_many :record_links, always_include_linkage_data: true

end
