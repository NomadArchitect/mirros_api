class Setting < ApplicationRecord

  self.primary_key = 'slug'
  validates :slug, uniqueness: true

  extend FriendlyId
  friendly_id :category_and_key, use: :slugged

  def category_and_key
    "#{category}_#{key}"
  end

  def get_options
    o = SettingOptions.get_options_yaml[slug.to_sym]
    o = [] if o.nil?
    o
  end

end
