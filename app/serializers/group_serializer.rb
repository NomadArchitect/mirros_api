class GroupSerializer < ActiveModel::Serializer
  attributes :id, :name
  
  has_many :components
  has_many :sources
  belongs_to :category
end
