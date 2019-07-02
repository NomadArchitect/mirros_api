require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

require_relative '../app/controllers/concerns/installable'
require_relative 'versions.rb'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups, *Installable::EXTENSION_TYPES)

module MirrOSApi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    ##############
    ### CUSTOM ###
    ##############

    config.i18n.default_locale = :en
    config.i18n.enforce_available_locales = false

    # Load instances models
    config.autoload_paths += %W[#{config.root}/app/models/instances]
    config.autoload_paths += %W[#{config.root}/app/models/group_schemas]
    config.autoload_paths += %W[#{config.root}/app/resources/group_schemas]

    API_HOST = 'api.glancr.de'.freeze
    GEM_SERVER = 'gems.marco-roth.ch'.freeze # localhost:9292 for geminabox
    SETUP_IP = '192.168.8.1'.freeze # Fixed IP of the internal setup WiFi AP.

    DEFAULT_WIDGETS = %i[
      clock
      countdown
      current_date
      calendar_event_list
      owm_current_weather
      owm_forecast
      text_field
      ticker
    ].freeze

    DEFAULT_SOURCES = %i[
      openweathermap
      ical
      rss_feeds
    ].freeze

    config.action_cable.allowed_request_origins = [
      /localhost:\d{2,4}/,
      /\d{3}.\d{3}.\d{1,3}.\d{1,3}:\d{2,4}/, # local network access
      /[\w-]+.local:\d{2,4}/ # local network via bonjour / zeroconf
    ]

    # Set custom log path for terrapin commands.
    # TODO: Enable if sensitive commands can be filtered.
    # Terrapin::CommandLine.logger = Logger.new("#{Rails.root}/log/system_commands.log")
  end
end
