class Widget < ApplicationRecord
  serialize :languages, Array

  self.primary_key = 'slug'

  include Installable
  after_create :install
  after_update :update
  after_destroy :uninstall

  has_many :widget_instances, dependent: :destroy
  has_many :services, dependent: :destroy
  belongs_to :group, optional: true

  validates :name, uniqueness: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  def to_s
    name
  end
end
