require_relative 'boot'

require 'rails/all'
require_relative '../app/controllers/concerns/installable'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups, *Installable::EXTENSION_TYPES)

module MirrOSApi
  # Application constants and configuration.
  class Application < Rails::Application
    # If running in the snap, SNAP_VERSION should be set.
    # Dev and test should have a git environment available.
    VERSION = case Rails.env
              when 'production'
                ENV['SNAP_VERSION'] ||= '0.0.0'.freeze
              when 'development', 'test'
                Terrapin::CommandLine.new(
                  'git',
                  'describe --always',
                  expected_outcodes: [0, 1]
                ).run.chomp!.freeze ||= '0.0.0'.freeze
              else
                '0.0.0'.freeze
              end
    API_HOST = 'api.glancr.de'.freeze
    SETUP_IP = '192.168.8.1'.freeze # Fixed IP of the internal setup WiFi AP.

    DEFAULT_WIDGETS = %i[
      clock
      current_date
      calendar_event_list
      owm_current_weather
      owm_forecast
      text_field
      styling
      ticker
    ].freeze

    DEFAULT_SOURCES = %i[
      openweathermap
      ical
      rss_feeds
    ].freeze

    # Set custom log path for terrapin commands.
    # TODO: Enable if sensitive commands can be filtered.
    # Terrapin::CommandLine.logger = Logger.new("#{Rails.root}/log/system_commands.log")

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Load instances models
    config.autoload_paths += %W[#{config.root}/app/models/instances]
    config.autoload_paths += %W[#{config.root}/app/models/group_schemas]
    config.autoload_paths += %W[#{config.root}/app/resources/group_schemas]

    config.api_only = true
    config.action_controller.default_protect_from_forgery = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.i18n.default_locale = :en
    config.i18n.enforce_available_locales = false
  end
end
