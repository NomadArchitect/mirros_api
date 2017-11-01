class Category < ApplicationRecord
  has_many :categories
  belongs_to :category, optional: true
end
