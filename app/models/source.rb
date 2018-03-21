class Source < ApplicationRecord
  has_many :source_instances, dependent: :destroy
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :categories
  has_many :widgets, through: :groups

  extend FriendlyId
  friendly_id :name, use: :slugged

  def to_s
    name
  end
end
