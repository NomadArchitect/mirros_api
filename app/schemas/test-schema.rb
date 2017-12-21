require "json"
require "json-schema"

schema = File.read("components.json")
json = JSON.parse(File.read("component.json")).to_hash

validator = JSON::Validator.fully_validate(schema, json)

if validator.count == 0
  puts "valid"
else
  puts "error"
  puts validator
end
