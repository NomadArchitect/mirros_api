class Widget < ApplicationRecord
  self.primary_key = 'slug'

  include Installable

  has_many :widget_instances, dependent: :destroy
  belongs_to :group, optional: true

  validates :name, presence: true, uniqueness: true
  validates :title, presence: true
  validates :description, presence: true
  validates :version, presence: true, format: /[0-9].[0-9].[0-9]/
  validates :download, presence: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  def to_s
    name
  end

  def pre_installed?
    MirrOSApi::Application::DEFAULT_WIDGETS.include?(slug)
  end

  def engine_class
    engine_name = "#{id.camelize}::Engine"

    begin
      engine = engine_name.constantize
    rescue NameError
      engine = "Mirros::Widget::#{engine_name}".safe_constantize
    end

    engine
  end
end
