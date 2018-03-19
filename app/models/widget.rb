class Widget < ApplicationRecord
  has_many :widget_instances, dependent: :destroy
  has_many :services, dependent: :destroy, inverse_of: 'provider'
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :categories

  def to_s
    name
  end

  def sources
    groups.map(&:sources).first
  end
end
