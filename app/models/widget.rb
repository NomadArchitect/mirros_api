class Widget < ApplicationRecord
  has_many :widget_instances, dependent: :destroy
  has_many :services, dependent: :destroy
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :categories

  def to_s
    name
  end

  # TODO: add as ActiveRecord relation
  def sources
    s = []
    groups.each do |g|
      s += Source.select {|s| s.groups.to_a.include?(g) }
    end
    s
  end

end


# Source.select {|s| s.groups.to_a.include?(Widget.first.groups.to_a) }
# Source.select {|s| s.groups.each { |g| Widget.first.groups.include?(g)} }
# Source.select {|s| (s.groups.to_a && self.groups.to_a).count > 1 }
