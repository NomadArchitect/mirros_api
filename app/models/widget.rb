class Widget < ExtensionBase
  # Primary key must be set in the inheriting class.
  self.primary_key = 'slug'
  # Use slugged version of name as a predictable ID.
  include FriendlyId
  friendly_id :name, use: :slugged

  has_many :widget_instances, dependent: :destroy
  belongs_to :group, optional: true

  validates :title, presence: true
  validates :description, presence: true
  validates :version, presence: true, format: /[0-9].[0-9].[0-9]/
  validates :download, presence: true

  def pre_installed?
    MirrOSApi::Application::DEFAULT_WIDGETS.include?(slug)
  end

end
