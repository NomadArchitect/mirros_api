class Source < ApplicationRecord
  self.primary_key = 'slug'

  include Installable

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
