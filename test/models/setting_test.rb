# frozen_string_literal: true

require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  fixtures :settings # TODO: Remove once test_helper is active

  test 'Prevents enabling board rotation when multi-board feature is off' do
    assert settings('system_multipleboards').value.eql?('off')
    setting = settings('system_boardrotation')
    setting.update(value: 'on')

    assert_invalid(
      setting,
      value: 'Please enable `multiple boards` first'
    )
  end

  test 'Enables board rotation when system.multipleBoards is active' do
    assert settings('system_multipleboards').update(value: 'on') # update should succeed with `true`

    setting = settings('system_boardrotation')
    setting.update(value: 'on')

    assert setting.valid?
  end

  test 'Prevents setting an invalid board rotation interval' do
    setting = settings('system_boardrotationinterval')
    setting.update(value: 'fnord')

    assert_invalid(
      setting,
      value: 'fnord is not a valid interval expression. Schema is `<integer>m`'
    )
  end

  test 'Saves a valid board rotation interval' do
    setting = settings('system_boardrotationinterval')
    setting.update(value: '5m')

    assert setting.valid?
  end
end
