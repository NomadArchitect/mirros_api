class SourceResource < JSONAPI::Resource
  attributes :name, :author, :version
  has_many :source_instances
end
