# frozen_string_literal: true

class RecordableResource < JSONAPI::Resource
  abstract
  immutable
  exclude_links :default
end
