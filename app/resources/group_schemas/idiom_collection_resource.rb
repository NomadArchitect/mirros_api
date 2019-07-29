class IdiomCollectionResource < RecordableResource
  model_name 'GroupSchemas::IdiomCollection'
  attributes :collection_name, :items
  key_type :string

  def items
    @model.items.as_json
  end
end
