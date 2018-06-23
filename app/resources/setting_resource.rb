class SettingResource < JSONAPI::Resource
  primary_key :slug
  key_type :string

  attributes :category, :key, :value

  def self.updatable_fields(context)
    super - [:category, :key]
  end
end
