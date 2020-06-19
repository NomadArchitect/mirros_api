# frozen_string_literal: true

require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  fixtures :settings # TODO: Remove once test_helper is active

  test 'prevents changing a premium setting without a valid license' do
    license = settings('personal_productkey')
    license.update(value: '')

    premium_setting = settings('system_showerrornotifications')
    premium_setting.update(value: 'off')

    assert_invalid(
      premium_setting,
      system_showerrornotifications: 'this setting requires a valid product key.'
    )
  end

  test 'Rejects an invalid product key' do
    setting = settings('personal_productkey')
    setting.update(value: 'fnord')

    assert_invalid(setting, value: "#{setting.value} is not a valid product key.")
  end

  test 'Saves a valid product key' do
    setting = settings('personal_productkey')
    setting.update(value: '173AB351-D746-48CD-ACD2-764BE02AF52F')

    assert setting.valid?
  end

  test 'Removing a product key resets premium features' do
    license = settings('personal_productkey')
    license.value = '173AB351-D746-48CD-ACD2-764BE02AF52F'
    license.save

    premium_setting = settings('system_showerrornotifications')
    premium_setting.save

    premium_setting.update(value: 'off')

    license.update(value: '')
    assert license.valid?

    assert Setting.find(premium_setting.id).value.eql? 'on'
  end
end
