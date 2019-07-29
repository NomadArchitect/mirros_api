class IdiomCollectionResource < RecordableResource
  model_name 'GroupSchemas::IdiomCollection'
  attributes :collection_name, :items
  key_type :string

  def items
    @model.items.as_json(except: %i[idiom_collection_id uid])
  end
end
