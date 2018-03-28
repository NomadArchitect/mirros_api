class Group < ApplicationRecord
  has_and_belongs_to_many :widgets
  has_and_belongs_to_many :sources
  has_and_belongs_to_many :categories

  validates :name, uniqueness: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  def to_s
    name
  end

end
