# frozen_string_literal: true

class Source < ApplicationRecord
  self.primary_key = 'slug'

  include Installable

  has_many :source_instances, dependent: :destroy
  has_and_belongs_to_many :groups

  validates :name, uniqueness: true

  extend FriendlyId
  friendly_id :name, use: :slugged

  def to_s
    name
  end

  def pre_installed?
    MirrOSApi::Application::DEFAULT_SOURCES.include?(slug)
  end

  def engine_class
    find_source_class('Engine')
  end

  def hooks_class
    find_source_class('Hooks')
  end

  private

  def find_source_class(type)
    klass_name = "#{id.camelize}::#{type}"

    begin
      klass = klass_name.constantize
    rescue NameError
      klass = "Mirros::Source::#{klass_name}".safe_constantize
    end

    klass
  end
end
