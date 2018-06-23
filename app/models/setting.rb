class Setting < ApplicationRecord

  self.primary_key = 'slug'
  validates :slug, uniqueness: true

  extend FriendlyId
  friendly_id :category_and_key, use: :slugged

  def category_and_key
    "#{category}-#{key}"
  end
end
