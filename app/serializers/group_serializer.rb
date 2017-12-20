class GroupSerializer < ActiveModel::Serializer
  attributes :id, :name

  has_many :components
  has_many :sources
  has_many :categories
end
