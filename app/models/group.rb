class Group < ApplicationRecord
  self.primary_key = :name

  has_many :widgets
  has_and_belongs_to_many :sources

  validates :name, uniqueness: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  def to_s
    name
  end
end
