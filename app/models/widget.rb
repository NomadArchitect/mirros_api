class Widget < ApplicationRecord
  # serialize :languages, Array if Rails.env.development?

  self.primary_key = 'slug'

  include Installable
  after_create :install
  after_update :update
  before_destroy :uninstall

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
end
