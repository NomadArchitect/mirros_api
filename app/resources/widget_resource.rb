class WidgetResource < JSONAPI::Resource
  has_many :services
  has_many :widget_instances
end
