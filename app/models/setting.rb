class Setting < ApplicationRecord

  self.primary_key = 'slug'
  validates :slug, uniqueness: true

  extend FriendlyId
  friendly_id :category_and_key, use: :slugged

  def category_and_key
    "#{category}_#{key}"
  end

  def self.get_options(key)
    o = SettingOptions.get_options_yaml[key.to_sym]
    o = [] if o.nil?
    o
  end

end
