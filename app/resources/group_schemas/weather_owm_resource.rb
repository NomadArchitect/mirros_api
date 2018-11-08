class WeatherOwmResource < RecordableResource
  model_name 'GroupSchemas::WeatherOwm'
  attributes :dt_txt, :forecast, :unit
end
