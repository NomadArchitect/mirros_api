class Source < ApplicationRecord
  has_many :source_instances, dependent: :destroy
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :categories

  def self.all_engines
    Rails::Engine.subclasses-[ActionView::Railtie, ActionCable::Engine]
  end

  def to_s
    name
  end

  # TODO: add as ActiveRecord relation
  def components
    c = []
    groups.each do |g|
      c += Component.select {|s| s.groups.to_a.include?(g) }
    end
    c
  end

end
