# JSON:API-compliant resource model for Sources.
class SourceResource < JSONAPI::Resource

  include Installable
  after_create :install
  after_update :update
  before_remove :uninstall

  primary_key :slug
  key_type :string

  attributes :name, :title, :description, :creator, :version, :website, :download
  has_many :source_instances, always_include_linkage_data: true
  has_many :groups, always_include_linkage_data: true
end
