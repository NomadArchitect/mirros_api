class WeatherOwmResource < RecordableResource
  model_name 'GroupSchemas::WeatherOwm'
  key_type :string
  attributes :location_name, :entries, :sunrise, :sunset

  def entries
    @model.entries.sort_by(&:dt_txt).as_json
  end
end
