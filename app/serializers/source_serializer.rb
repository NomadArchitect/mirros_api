class SourceSerializer < ActiveModel::Serializer
  attributes :id, :name, :author, :version, :website, :repository

  has_many :source_instances
  has_many :groups
  has_many :categories
end
