class Category < ApplicationRecord
  has_many :categories
  belongs_to :category, optional: true

  has_many :components
  has_many :sources
  has_many :groups
end
