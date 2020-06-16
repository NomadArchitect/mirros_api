require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def jsonapi_headers
      {
        'ACCEPT': 'application/vnd.api+json',
        'CONTENT-TYPE': 'application/vnd.api+json'
      }
    end

    def jsonapi_wrap(type, resource)
      {
        data: resource.as_json.merge(type: type)
      }
    end

    # Taken from https://stackoverflow.com/a/42618473/2915244
    def assert_invalid(record, options)
      assert_predicate record, :invalid?

      options.each do |attribute, message|
        assert record.errors.added?(attribute, message), "Expected #{attribute} to have the following error: #{message}"
      end
    end
  end
end
