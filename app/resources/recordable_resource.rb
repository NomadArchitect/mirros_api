class RecordableResource < JSONAPI::Resource
  abstract
  immutable
  exclude_links :default
end
