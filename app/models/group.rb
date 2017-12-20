class Group < ApplicationRecord
  has_and_belongs_to_many :components
  has_and_belongs_to_many :sources
  has_and_belongs_to_many :categories
end
