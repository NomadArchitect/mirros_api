class WidgetResource < JSONAPI::Resource

  include Installable
  after_create :install
  after_update :update
  after_remove :uninstall

  primary_key :slug
  key_type :string

  attributes :name, :title, :description, :icon, :version, :creator, :website, :download, :languages
  has_many :services, always_include_linkage_data: true
  has_many :widget_instances, always_include_linkage_data: true
  has_many :groups, always_include_linkage_data: true
end
