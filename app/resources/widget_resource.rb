class WidgetResource < JSONAPI::Resource
  immutable

  attributes :name, :icon, :version, :creator, :website, :languages, :installed
  has_many :services
  has_many :widget_instances
end
