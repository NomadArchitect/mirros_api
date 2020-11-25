class SystemState < ApplicationRecord
  validates_uniqueness_of :variable
end
