require 'test_helper'

class RestartBrowserJobTest < ActiveJob::TestCase
  test 'it does nothing outside snap environment' do
    job = RestartBrowserJob.new
    if OS.linux? && !System.running_in_snap?
      assert_raises DBus::Error do
        job.perform
      end
    else
      assert_nil job.perform
    end
  end
end
