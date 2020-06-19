class RegistrationHandler

  PREMIUM_SETTINGS = {
    system_showerrornotifications: {
      default: 'on'
    },
    system_themecolor: {
      default: '#8ba4c1'
    },
    system_boardrotation: {
      default: 'off'
    },
    system_boardrotationinterval: {
      default: '1'
    }
  }.freeze

  REQUIRES_LICENSE = PREMIUM_SETTINGS.keys.freeze

  def self.reset_premium_to_default
    PREMIUM_SETTINGS.each_pair do |slug, opts|
      # Use `update_column` to bypass validations, which would prevent updating
      # a setting that requires a license.
      Setting.find_by(slug: slug)&.update_attribute(:value, opts[:default])
    end
  end

  def self.setting_requires_license?(slug)
    REQUIRES_LICENSE.include?(slug.to_sym)
  end

  def initialize(product_key = nil)
    @product_key = product_key || Setting.find('personal_productkey')&.value
  end

  def deregister?
    # TODO: Future version can handle actual de-registration here
    @product_key.blank?
  end

  def product_key_valid?
    @product_key.match?(
      /^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$/
    )
  end

  def remove_product_key
    Setting.find_by(slug: :personal_productkey).update(value: '')
  end
end
