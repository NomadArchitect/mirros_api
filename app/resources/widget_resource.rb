class WidgetResource < JSONAPI::Resource

  include Installable
  after_create :install
  before_remove :uninstall

  primary_key :slug
  key_type :string
  attributes :name, :icon, :version, :creator, :website, :download, :languages
  has_many :services
  has_many :widget_instances
  has_many :groups
  has_many :sources, through: :groups
end
