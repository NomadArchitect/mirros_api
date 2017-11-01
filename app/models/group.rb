class Group < ApplicationRecord
  has_many :components
  has_many :sources
end
