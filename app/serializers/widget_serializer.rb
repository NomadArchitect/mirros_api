class WidgetSerializer < ActiveModel::Serializer
  attributes :id, :name, :author, :version, :website, :repository
  has_many :widget_instances, dependent: :destroy
  has_many :groups
  has_many :categories
end
