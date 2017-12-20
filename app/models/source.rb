class Source < ApplicationRecord
  has_many :source_instances, dependent: :destroy
  has_and_belongs_to_many :groups
  has_and_belongs_to_many :category

  def self.all
    Rails::Engine.subclasses-[ActionView::Railtie, ActionCable::Engine]
  end
end
