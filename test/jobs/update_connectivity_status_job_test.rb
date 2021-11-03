require 'test_helper'

class UpdateConnectivityStatusJobTest < ActiveJob::TestCase
  test 'it checks ' do

    if OS.linux?
      # TODO: Stub network-manager or ensure we are running it
    else

    end
  end
end
