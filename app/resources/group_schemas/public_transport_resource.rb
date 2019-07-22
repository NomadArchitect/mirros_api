class PublicTransportResource < RecordableResource
  model_name 'GroupSchemas::PublicTransport'
  attributes :station_name, :departures
  key_type :string

  def departures
    @model
      .departures
      .sort_by(&:departure)
      .reverse.as_json
  end
end
