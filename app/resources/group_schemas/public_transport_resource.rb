class PublicTransportResource < RecordableResource
  model_name 'GroupSchemas::PublicTransport'
  attributes :uuid, :departure, :delay_minutes, :line, :direction, :transit_type, :platform
end
