class CategorySerializer < ActiveModel::Serializer
  attributes :id, :name, :website
  belongs_to :category
  has_many :categories
  has_many :widgets
  has_many :sources
  has_many :groups
end
