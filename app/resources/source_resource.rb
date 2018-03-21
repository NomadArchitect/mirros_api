class SourceResource < JSONAPI::Resource
  primary_key :slug
  key_type :string
  attributes :name, :creator, :version
  has_many :source_instances, always_include_linkage_data: true
end
