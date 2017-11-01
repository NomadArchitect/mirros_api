class ComponentSerializer < ActiveModel::Serializer
  attributes :id, :name, :author, :version, :website, :repository
  has_many :component_instances, dependent: :destroy
  has_many :groups
  belongs_to :category
end
