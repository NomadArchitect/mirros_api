class Group < ApplicationRecord
  has_many :components
  has_many :sources
  belongs_to :category
end
