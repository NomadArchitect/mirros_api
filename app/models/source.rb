# frozen_string_literal: true

class Source < ExtensionBase
  # Primary key must be set in the inheriting class.
  self.primary_key = 'slug'
  # Use slugged version of name as a predictable ID.
  include FriendlyId
  friendly_id :name, use: :slugged

  has_many :source_instances, dependent: :destroy
  has_and_belongs_to_many :groups

  # Checks whether the corresponding source gem was bundled with mirr.OS.
  # @return [TrueClass, FalseClass] True if the source was included on install.
  def pre_installed?
    MirrOSApi::Application::DEFAULT_SOURCES.include?(slug)
  end

end
