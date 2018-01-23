class Group < ApplicationRecord
  has_and_belongs_to_many :widgets
  has_and_belongs_to_many :sources
  has_and_belongs_to_many :categories

  def to_s
    name
  end

end
