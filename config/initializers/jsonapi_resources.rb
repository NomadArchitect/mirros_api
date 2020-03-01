# frozen_string_literal: true

JSONAPI.configure do |config|
  config.always_include_to_one_linkage_data = true
  config.always_include_to_many_linkage_data = true # Not implemented as of v0.9, needs to be specified on each to-many relation
  config.json_key_format = :camelized_key
end
