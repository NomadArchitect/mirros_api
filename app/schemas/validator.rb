require "json"
require "json-schema"

def validate_schema(schema = {}, json)
  schema = File.read(schema)
  json = JSON.parse(File.read(json).to_s).to_hash

  validator = JSON::Validator.fully_validate(schema, json)

  if validator.count == 0
    return { valid: true, errors: [] }
  else
    return { valid: false, errors: validator }
  end
end

json_file = "app/schemas/widget.json"
schema_file = "app/schemas/widgets.json"

puts validate_schema(schema_file, json_file)
