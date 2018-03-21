class WidgetResource < JSONAPI::Resource
  primary_key :slug
  key_type :string
  attributes :name, :icon, :version, :creator, :website, :languages
  has_many :services
  has_many :widget_instances
end
