# frozen_string_literal: true

class Setting < ApplicationRecord
  ALLOW_WHITESPACE = %w[network_ssid network_password system_adminpassword].freeze

  extend FriendlyId
  friendly_id :category_and_key, use: :slugged

  before_update :apply_setting, if: :auto_applicable?
  after_update :update_cache, :check_setup_status
  after_update :reset_premium_settings, if: :changes_product_key?
  after_update :restart_application, if: -> { slug.eql?('system_timezone') }
  before_validation :check_license_status, unless: :changes_product_key?
  before_validation :strip_whitespace, unless: -> { ALLOW_WHITESPACE.include?(slug) }

  self.primary_key = 'slug'
  validates :slug, uniqueness: true

  # FIXME: Refactor with custom validator class to avoid condition bloat.
  validates_each :value do |record, attr, value|
    case record.slug
    when 'system_timezone'
      next unless ActiveSupport::TimeZone[value.to_s].nil?

      record.errors.add(attr, "#{value} is not a valid timezone!")

    when /system_backgroundcolor|system_fontcolor/
      next if value.match?(/^#[0-9A-F]{6}$/i) # Check for valid hex color values.

      record.errors.add(attr, "#{value} is not a valid CSS color!")

    when 'system_activeboard'
      next if Board.exists?(value)

      record.errors.add(attr, "Cannot find board with ID #{value}")

    when 'personal_productkey'
      handler = RegistrationHandler.new(value)
      next if handler.product_key_valid? || handler.deregister?

      record.errors.add(attr, "#{value} is not a valid product key.")

    when 'system_boardrotation'
      unless Setting.find_by(slug: 'system_multipleboards')&.value.eql?('on')
        record.errors.add(attr, 'Please enable `multiple boards` first')
        next
      end

      opts = record.options
      next if opts.key?(value)

      record.errors.add(
        attr,
        "#{value} is not a valid option for #{attr}, options are: #{opts.keys}"
      )

    when 'system_boardrotationinterval'
      begin
        Rufus::Scheduler.parse_in value
      rescue ArgumentError
        record.errors.add(
          attr,
          "#{value} is not a valid interval expression. Schema is `<integer>m`"
        )
      end
    when 'system_scheduleshutdown'
      begin
        record.errors.add(attr, "#{value} is not a valid time of day. Schema is `hh:mm`") if value.present? && value.to_time.blank?
      rescue StandardError
        record.errors.add(attr, "#{value} is not a valid time of day. Schema is `hh:mm`")
      end

    else
      opts = record.options
      # Check for empty options in case this setting has no options (free-form)
      next if opts.key?(value) || opts.empty?

      record.errors.add(
        attr,
        "#{value} is not a valid option for #{attr}, options are: #{opts.keys}"
      )
    end
  end

  def changes_product_key?
    slug.eql? 'personal_productkey'
  end

  def reset_premium_settings
    return if RegistrationHandler.new.product_key_valid?

    RegistrationHandler.reset_premium_to_default
  end

  def check_license_status
    return unless RegistrationHandler.setting_requires_license?(slug)

    return if RegistrationHandler.new.product_key_valid?

    errors.add(slug, 'this setting requires a valid product key.')
  end

  def category_and_key
    "#{category}_#{key}"
  end

  # Gets a hash of available options for a setting, if defined.
  # @return [ActiveSupport::HashWithIndifferentAccess,Hash] Hash of options for this setting.
  def options
    # FIXME: Maybe cleaner to extract?
    if slug.eql? 'system_timezone'
      ActiveSupport::TimeZone.all.map { |tz| { id: tz.tzinfo.identifier, name: tz.to_s } }
    else
      options_file = File.read(Rails.root.join('app/lib/setting_options.yml'))
      # TODO: If we require Ruby logic in the YAML file, use ERB.new(options_file).result instead of options_file
      o = YAML.safe_load(options_file).with_indifferent_access[slug.to_sym]
      o.nil? ? {} : o
    end
  end

  # Forces the StateCache singleton to re-evaluate if the setup has been completed.
  # @return [nil]
  def check_setup_status
    StateCache.refresh_setup_complete System.setup_completed?
  end

  # Update the SettingsCache singleton for this setting.
  # @return [String] The updated value
  def update_cache
    SettingsCache.s[slug.to_sym] = value
    StateCache.refresh_registered(RegistrationHandler.new.product_key_valid?) if slug.eql? 'personal_productkey'
  end

  # Check whether a setting can and should be applied automatically by `apply_setting`.
  # @return [TrueClass, FalseClass] True if the setting should be auto-applied by SettingExecution, false otherwise.
  def auto_applicable?
    %i[system_timezone system_boardrotation system_boardrotationinterval system_scheduleshutdown].include?(slug.to_sym)
  end

  # Applies a setting automatically. Requires an executor class with the same constant name as the setting's category,
  # which has a class method corresponding to the setting's `key` attribute. E.g. category `system` and
  # key `scheduleShutdown` would invoke SettingExecution::System.schedule_shutdown.
  def apply_setting
    executor = "SettingExecution::#{category.capitalize}".safe_constantize
    method_name = key.underscore
    executor.send(method_name, value) if executor.respond_to?(method_name)
  end

  # Restart the application for settings that require a restart.
  # Currently only used for system_timezone, @see https://github.com/rails/rails/issues/24748 issue details.
  def restart_application
    ::System.restart_application if Rails.const_defined?('Server')
  end

  private

  # Strips left/right whitespace from the `value` attribute.
  # @return [String, nil]
  def strip_whitespace
    value.strip!
  end
end
