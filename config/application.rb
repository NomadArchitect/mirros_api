# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'action_cable/engine'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
# require "sprockets/railtie"
require 'rails/test_unit/railtie'

require_relative '../app/models/concerns/installable'
require_relative 'versions.rb'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups, *Installable::EXTENSION_TYPES)

module MirrOSApi
  class Application < Rails::Application

    # Filters dependencies by bundler group and whether they were installed manually, i.e. not during build time.
    # @param [Symbol] group The bundler group to filter by
    # @param [TrueClass|FalseClass] manually_installed Return gems that were manually installed, default `false`
    def gems_in_extension_group(group:, manually_installed: false)
      filter_method = manually_installed ? :select : :reject
      Bundler.load
        .current_dependencies
        .select { |dep| dep.groups.include?(group.to_sym) }.send(filter_method) { |dep| dep.groups.include?(:manual) }.map(&:name).freeze
    end

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

    # Configure the application's default timezone, so that all threads (esp. scheduler) have the correct setting.
    # We can't read the configured timezone from the DB as ActiveModel is not initialized yet. Changing it later in an
    # initializer or even through controller actions has no effect, @see https://github.com/rails/rails/issues/24748
    # A manual SQL query would work as well, but we want to stay as close to the system time to avoid subtle errors.

    tz = if OS.linux?
           # Note: Reading /etc/timezone does not require snap interfaces so we shouldn't need error handling.
           Terrapin::CommandLine.new('cat', '/etc/timezone').run&.chomp!
         elsif OS.mac?
           Terrapin::CommandLine.new('readlink', '/etc/localtime').run&.chomp!&.partition('zoneinfo/')&.last
         else
           'UTC'
         end
    config.time_zone = tz unless tz.blank?

    # Load instances models
    config.autoload_paths += %W[#{config.root}/app/models/instances]
    config.autoload_paths += %W[#{config.root}/app/models/concerns]
    config.autoload_paths += %W[#{config.root}/app/models/group_schemas]
    config.autoload_paths += %W[#{config.root}/app/resources/group_schemas]

    # Load overrides
    config.autoload_paths += %W[#{config.root}/app/overrides/controllers]

    API_HOST = 'api.glancr.de'
    GEM_SERVER = 'extensions.glancr.net' # localhost:9292 for geminabox
    SETUP_IP = '192.168.8.1' # Fixed IP of the internal setup WiFi AP.

    DEFAULT_WIDGETS = Bundler.load
                        .current_dependencies
                        .select { |dep| dep.groups.include?(:widget) }.reject { |dep| dep.groups.include?(:manual) }.map(&:name).freeze

    DEFAULT_SOURCES = Bundler.load
                        .current_dependencies
                        .select { |dep| dep.groups.include?(:source) }.reject { |dep| dep.groups.include?(:manual) }.map(&:name).freeze

    config.action_cable.allowed_request_origins = [
      /localhost:\d{2,4}/,
      /\d{3}.\d{3}.\d{1,3}.\d{1,3}:\d{2,4}/, # local network access
      /[\w-]+.local:\d{2,4}/ # local network via bonjour / zeroconf
    ]

    # Serve image/svg+xml with the correct content type.
    # See https://github.com/rails/rails/issues/34665#issuecomment-445888009
    config.active_storage.content_types_to_serve_as_binary = config
                                                               .active_storage
                                                               .content_types_to_serve_as_binary
                                                               .reject { |ct| ct.eql?('image/svg+xml') }
    config.active_storage.content_types_allowed_inline = config
                                                           .active_storage
                                                           .content_types_allowed_inline
                                                           .dup
                                                           .push('image/svg+xml')
    # Set custom log path for terrapin commands.
    # TODO: Enable if sensitive commands can be filtered.
    # Terrapin::CommandLine.logger = Logger.new("#{Rails.root}/log/system_commands.log")
  end
end
