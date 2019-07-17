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

    # Add more helper methods to be used by all tests here...
  end
end
