class Source < ApplicationRecord
  has_many :source_instances, dependent: :destroy
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :categories

  def to_s
    name
  end

  def widgets
    groups.map(&:widgets).first
  end
end
