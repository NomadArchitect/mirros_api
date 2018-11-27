class Setting < ApplicationRecord
  self.primary_key = 'slug'
  validates :slug, uniqueness: true

  extend FriendlyId
  friendly_id :category_and_key, use: :slugged

  after_update :check_setup_status

  def category_and_key
    "#{category}_#{key}"
  end

  # Gets a hash of available options for a setting, if defined.
  # @return [ActiveSupport::HashWithIndifferentAccess] Hash of options for this setting.
  def get_options
    options_file = File.read("#{Rails.root}/app/lib/setting_options.yml")
    # TODO: If we require Ruby logic in the YAML file, use ERB.new(options_file).result instead of options_file
    o = YAML.load(options_file).with_indifferent_access[slug.to_sym]
    o = {} if o.nil?
    o
  end

  def check_setup_status
    Rails.configuration.setup_complete = System.setup_completed?
  end

end
