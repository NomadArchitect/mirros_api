class GroupSerializer < ActiveModel::Serializer
  attributes :id, :name

  has_many :widgets
  has_many :sources
  has_many :categories
end
