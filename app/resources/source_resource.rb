class SourceResource < JSONAPI::Resource
  immutable
  
  attributes :name, :author, :version
  has_many :source_instances,
  always_include_linkage_data: true
end
