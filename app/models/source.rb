class Source < ApplicationRecord
  self.primary_key = 'slug'

  include Installable
  after_create :install_gem
  after_create_commit :post_install
  after_update :update_gem
  after_update_commit :post_update
  before_destroy :uninstall_gem
  after_destroy_commit :post_uninstall

  has_many :source_instances, dependent: :destroy
  has_and_belongs_to_many :groups

  validates :name, uniqueness: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  def to_s
    name
  end
end
