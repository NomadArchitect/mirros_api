class Source < ApplicationRecord
  self.primary_key = 'slug'

  include Installable
  after_create :install_gem, unless: :pre_installed?
  after_create_commit :post_install, unless: :pre_installed?
  after_update :update_gem, unless: :pre_installed?
  after_update_commit :post_update, unless: :pre_installed?
  before_destroy :uninstall_gem, unless: :pre_installed?
  after_destroy_commit :post_uninstall, unless: :pre_installed?

  has_many :source_instances, dependent: :destroy
  has_and_belongs_to_many :groups

  validates :name, uniqueness: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  def to_s
    name
  end

  def pre_installed?
    MirrOSApi::Application::DEFAULT_SOURCES.include?(slug)
  end
end
