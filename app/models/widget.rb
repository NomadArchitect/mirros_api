class Widget < ApplicationRecord
  # serialize :languages, Array if Rails.env.development?

  self.primary_key = 'slug'

  include Installable
  after_create :install_gem, unless: :pre_installed?
  after_create_commit :post_install, unless: :pre_installed?
  after_update :update_gem, unless: :pre_installed?
  after_update_commit :post_update, unless: :pre_installed?
  before_destroy :uninstall_gem, unless: :pre_installed?
  after_destroy_commit :post_uninstall, unless: :pre_installed?

  has_many :widget_instances, dependent: :destroy
  belongs_to :group, optional: true

  validates :name, presence: true, uniqueness: true
  validates :title, presence: true
  validates :description, presence: true
  validates :version, presence: true, format: /[0-9].[0-9].[0-9]/
  validates :download, presence: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  def to_s
    name
  end

  def pre_installed?
    MirrOSApi::Application::DEFAULT_WIDGETS.include?(slug)
  end
end
