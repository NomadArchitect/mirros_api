class SettingResource < JSONAPI::Resource
  caching

  primary_key :slug
  key_type :string

  filter :category

  attributes :category, :key, :value
  attribute :options

  # Add predefined options for this setting if available.
  def options
    @model.get_options
  end

  def self.updatable_fields(context)
    super - [:category, :key]
  end

end
