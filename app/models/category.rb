class Category < ApplicationRecord
  has_many :categories
  belongs_to :category, optional: true

  has_and_belongs_to_many :components
  has_and_belongs_to_many :sources
  has_and_belongs_to_many :groups
end
