require "json"
require "json-schema"


def validate_schema(schema = {}, json)
  schema = File.read(schema)
  json = JSON.parse(json.to_s).to_hash

  validator = JSON::Validator.fully_validate(schema, json)

  if validator.count == 0
    return { valid: true, errors: [] }
  else
    return { valid: false, errors: validator }
  end
end


puts validate_schema("widgets.json", File.read("widget.json"))
