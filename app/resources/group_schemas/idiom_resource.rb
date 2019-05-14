class IdiomResource < JSONAPI::Resource
  model_name 'GroupSchemas::Idiom'
  attributes :message, :title, :author, :language, :date
end
