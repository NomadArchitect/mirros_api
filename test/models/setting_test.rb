# frozen_string_literal: true

require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  fixtures :settings # TODO: Remove once test_helper is active

  test 'prevents changing a premium setting without a valid license' do
    save_invalid_product_key

    premium_setting = settings('system_showerrornotifications')
    premium_setting.update(value: 'off')

    assert_invalid(
      premium_setting,
      system_showerrornotifications: 'this setting requires a valid product key.'
    )
  end

  test 'Rejects an invalid product key' do
    setting = save_invalid_product_key
    assert_invalid(setting, value: "#{setting.value} is not a valid product key.")
  end

  test 'Saves a valid product key' do
    setting = save_valid_product_key
    assert setting.valid?
  end

  test 'Removing a product key resets premium features' do
    license = save_valid_product_key
    premium_setting = settings('system_showerrornotifications')
    premium_setting.update(value: 'off')
    license.update(value: '')

    assert license.valid?
    assert Setting.find(premium_setting.id).value.eql? 'on'
  end

  test 'Prevents enabling board rotation when multi-board feature is off' do
    save_valid_product_key
    assert settings('system_multipleboards').value.eql?('off')
    setting = settings('system_boardrotation')
    setting.update(value: 'on')

    assert_invalid(
      setting,
      value: 'Please enable `multiple boards` first'
    )
  end

  test 'Enables board rotation when system.multipleBoards is active' do
    save_valid_product_key
    assert settings('system_multipleboards').update(value: 'on') # update should succeed with `true`

    setting = settings('system_boardrotation')
    setting.update(value: 'on')

    assert setting.valid?
  end

  test 'Prevents setting an invalid board rotation interval' do
    save_valid_product_key
    setting = settings('system_boardrotationinterval')
    setting.update(value: 'fnord')

    assert_invalid(
      setting,
      value: 'fnord is not a valid interval expression. Schema is `<integer>m`'
    )
  end

  test 'Saves a valid board rotation interval' do
    save_valid_product_key
    setting = settings('system_boardrotationinterval')
    setting.update(value: '5m')

    assert setting.valid?
  end
end
