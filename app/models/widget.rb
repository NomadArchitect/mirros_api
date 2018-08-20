class Widget < ApplicationRecord
  self.primary_key = 'slug'

  has_many :widget_instances, dependent: :destroy
  has_many :services, dependent: :destroy
  belongs_to :group

  validates :name, uniqueness: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  def to_s
    name
  end
end
