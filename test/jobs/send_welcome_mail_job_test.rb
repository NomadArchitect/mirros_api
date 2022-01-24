# frozen_string_literal: true

require 'test_helper'

class SendWelcomeMailJobTest < ActiveJob::TestCase

  test 'it returns if setup is not completed' do
    Setting.create category: :network, key: :connectionType, value: :lan
    Setting.create category: :personal, key: :email, value: 'test@example.org'

    assert_not System.setup_completed?

    job = SendWelcomeMailJob.new
    job.perform

    assert_not EnvironmentVariable.find_by(variable: 'welcome_email_sent')&.value.eql? true
  end

  test 'it returns if the welcome mail has already been sent' do
    Setting.create category: :network, key: :connectionType, value: :lan
    Setting.create category: :personal, key: :email, value: 'test@example.org'
    Setting.create category: :personal, key: :name, value: 'Tester'
    EnvironmentVariable.find_or_initialize_by(variable: 'welcome_email_sent').update(value: true)

    assert System.setup_completed?
  end
end
