# frozen_string_literal: true

require 'test_helper'

class SettingTest < ActiveSupport::TestCase
  VALID_LICENSE = '173AB351-D746-48CD-ACD2-764BE02AF52F'
  INVALID_LICENSE = 'fnord'

  fixtures :settings # TODO: Remove once test_helper is active

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
end
