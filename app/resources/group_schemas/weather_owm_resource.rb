module GroupSchemas
  class WeatherOwmResource < RecordableResource
    caching

    model_name 'GroupSchemas::WeatherOwm'
    attributes :dt_txt, :forecast, :unit
  end
end
