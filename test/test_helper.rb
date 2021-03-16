# frozen_string_literal: true

require File.expand_path('../config/environment', __dir__)
require 'rails/test_help'

module ActiveSupport
  class TestCase
    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    VALID_LICENSE = '173AB351-D746-48CD-ACD2-764BE02AF52F'
    INVALID_LICENSE = 'fnord'

    def save_valid_product_key
      license = settings('personal_productkey')
      license.update(value: VALID_LICENSE)
      license
    end

    def save_invalid_product_key
      license = settings('personal_productkey')
      license.update(value: INVALID_LICENSE)
      license
    end

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
