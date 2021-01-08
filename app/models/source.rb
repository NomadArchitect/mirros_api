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

  # Checks whether the corresponding source gem was bundled with mirr.OS.
  # @return [TrueClass, FalseClass] True if the source was included on install.
  def pre_installed?
    MirrOSApi::Application::DEFAULT_SOURCES.include?(slug)
  end

  # Returns the class constant for this source's Engine class.
  # @return [Class] The Engine class constant.
  def engine_class
    find_source_class('Engine')
  end

  # Returns the class constant for this source's Hooks implementation.
  # @return [Class] The Hooks class constant.
  def hooks_class
    @hooks_class ||= find_source_class('Hooks')
  end

  private

  # Find and constantize the given class from this source's gem.
  # @param [Object] type `Engine` or `Hooks`
  # @return [Class] The class constant for the given type.
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
