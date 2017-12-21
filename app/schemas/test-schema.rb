require "json"
require "json-schema"


#schema = JSON.parse(File.read("./components.json"))

#puts JSON::Validator.validate("components.json", { "a" => 5 }, :json => true)

schema = File.read("components.json")
json = File.read("component.json")

puts JSON::Validator.validate(schema, json, json: true, :validate_schema => true)
