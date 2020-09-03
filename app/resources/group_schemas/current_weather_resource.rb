class GroupSchemas::CurrentWeatherResource < RecordableResource
  model_name 'GroupSchemas::CurrentWeather'
  attributes :station_name, :entries; :location
  key_type :string

  def entries
    @model.entries.as_json(except: %i[current_weather_id uid])
  end
end
