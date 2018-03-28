# JSON:API-compliant resource model for Sources.
class SourceResource < JSONAPI::Resource

  include Installable
  after_create :install
  before_remove :uninstall

  primary_key :slug
  key_type :string
  attributes :name, :creator, :version, :website, :download
  has_many :source_instances, always_include_linkage_data: true
  has_many :groups
  has_many :widgets, through: :groups
end
