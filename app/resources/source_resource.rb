# JSON:API-compliant resource model for Sources.
class SourceResource < JSONAPI::Resource

  primary_key :slug
  key_type :string

  attributes :name,
             :title,
             :description,
             :creator,
             :version,
             :compatibility,
             :homepage,
             :download,
             :icon
  has_many :source_instances,
           always_include_linkage_data: true,
           exclude_links: [:self]
  has_many :groups,
           always_include_linkage_data: true,
           exclude_links: [:self]
end
