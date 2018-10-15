require_relative 'boot'

require 'rails/all'
require_relative '../app/controllers/concerns/installable'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups, *Installable::EXTENSION_TYPES)

module MirrOSApi
  class Application < Rails::Application

    VERSION = '0.1.0'.freeze

    # Set custom log path for terrapin commands. TODO: Enable if sensitive commands can be filtered.
    # Terrapin::CommandLine.logger = Logger.new("#{Rails.root}/log/system_commands.log")

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Load instances models
    config.autoload_paths += %W[#{config.root}/app/models/instances]
    config.autoload_paths += %W[#{config.root}/app/models/group_schemas]
    config.autoload_paths += %W[#{config.root}/app/resources/group_schemas]

    config.api_only = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = false

    config.active_record.sqlite3.represent_boolean_as_integer = true

  end
end
