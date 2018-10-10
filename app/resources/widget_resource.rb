class WidgetResource < JSONAPI::Resource

  primary_key :slug
  key_type :string

  attributes :name, :title, :description, :icon, :version, :creator, :website, :download, :languages
  has_many :services, always_include_linkage_data: true
  has_many :widget_instances, always_include_linkage_data: true
  has_one :group, optional: true
end
