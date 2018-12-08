# JSON:API-compliant resource model for Sources.
class SourceResource < JSONAPI::Resource
  caching

  primary_key :slug
  key_type :string

  attributes :name, :title, :description, :creator, :version, :homepage, :download, :icon
  has_many :source_instances, always_include_linkage_data: true
  has_many :groups, always_include_linkage_data: true
end
