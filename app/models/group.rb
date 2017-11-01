class Group < ApplicationRecord
  has_and_belongs_to_many :components
  has_and_belongs_to_many :sources
  belongs_to :category
end
