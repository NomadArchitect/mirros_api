class SettingResource < JSONAPI::Resource
  primary_key :slug
  key_type :string

  attributes :category, :key, :value
end
