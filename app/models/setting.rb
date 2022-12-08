# frozen_string_literal: true

class Setting < ApplicationRecord
  ALLOW_WHITESPACE = %w[network_ssid network_password system_adminpassword].freeze

  extend FriendlyId
  friendly_id :category_and_key, use: :slugged

  before_update :apply_setting, if: :auto_applicable?
  after_update :check_setup_status
  after_update :restart_application, if: -> { slug.eql?('system_timezone') }
  before_validation :strip_whitespace, unless: -> { ALLOW_WHITESPACE.include?(slug) }
  after_validation :modify_widget_colors, if: -> { slug.eql?('system_fontcolor') }

  self.primary_key = 'slug'
  validates :slug, uniqueness: true
  validates :value, setting: true

  # Get the value attribute for a given setting slug.
  # @param [String|Symbol] slug The setting's slug, defined by self.category_and_key
  # @return [String, nil]
  def self.value_for(slug)
    find_by(slug: slug)&.value
  end

  # Builds the slug for this setting.
  # @return [String (frozen)] category_key
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
      o || {}
    end
  end

  # Forces the StateCache singleton to re-evaluate if the setup has been completed.
  # @return [nil]
  def check_setup_status
    StateCache.put :setup_complete, System.setup_completed?
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

  # Update WidgetInstances which have the previous system_fontcolor configured, as the user will likely want them to
  # reflect the global change.
  def modify_widget_colors
    wi_with_default_color = WidgetInstance.where("styles->'$.font_color' = :previous_color", previous_color: value_was)
    changed_wi = wi_with_default_color.map(&:id)
    wi_with_default_color.update_all("styles = JSON_REPLACE(styles, '$.font_color', '#{value}')")
    # Reload models and broadcast changes, update_all does not trigger ApplicationRecord.after_commit
    # A simple Relation.reload would fail since the variable contains the WHERE query.
    WidgetInstance.find(changed_wi).each(&:broadcast)
  end

  private

  # Strips left/right whitespace from the `value` attribute.
  # @return [String, nil]
  def strip_whitespace
    value.strip!
  end
end
