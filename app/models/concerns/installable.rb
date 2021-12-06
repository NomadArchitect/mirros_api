# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/dependency'
require 'bundler/injector'
require 'bundler/installer'
require 'bundler/lockfile_generator'
require 'pathname'
require 'active_support/concern'

# Provides methods to install, update and uninstall widgets and sources.
module Installable
  extend ActiveSupport::Concern

  included do
    after_create :install_gem, unless: :pre_installed?
    after_create_commit :post_install, unless: :pre_installed?
    after_update :update_gem, unless: :pre_installed?
    after_update_commit :post_update, unless: :pre_installed?
    before_destroy :uninstall_gem, unless: :pre_installed?
    after_destroy_commit :post_uninstall, unless: :pre_installed?
  end

  EXTENSION_TYPES = %w[widget source].freeze
  ACTION_MAP = {
    create: 'install',
    update: 'update',
    destroy: 'uninstall'
  }.freeze

  class_methods do
    def without_callbacks(action)
      post_cb = ACTION_MAP[action.to_sym]
      callbacks = [
        [action.to_sym, :after, "#{post_cb}_gem".to_sym],
        [:commit, :after, "post_#{post_cb}".to_sym]
      ]
      callbacks.each { |cb| skip_callback(*cb) }
      yield
      callbacks.each { |cb| set_callback(*cb) }
    end
  end

  def install_gem
    setup_instance

    begin
      inject_gem
      Bundler::Installer.install(Bundler.root, new_definition, bundler_options)
    rescue Terrapin::CommandLineError, Bundler::BundlerError, Net::HTTPError => e
      Rails.logger.error "Error during installation of #{@gem}: #{e.message}"
      remove_from_gemfile
      bundler_rollback
      raise e
    end

    refresh_runtime

    case installed?(@gem, @version)
    when true
      Thread.new { System.restart_application }
    when false
      remove_from_gemfile
      bundler_rollback
      raise StandardError, "Extension #{@gem} was not properly installed, reverting"
    else
      Rails.logger.error "Could not determine install state of #{@gem}"
    end
  end

  # Update the extension to the passed version.
  def update_gem
    setup_instance
    prev_version = Bundler.definition.specs.[](@gem).first.version.to_s # Save previous version in case we need to reset.
    change_gem_version(@version)

    begin
      Bundler::Installer.install(Bundler.root,
                                 new_definition(gems: [@gem]),
                                 bundler_options)
    rescue Bundler::BundlerError => e
      Rails.logger.error "Error during update of #{@gem}: #{e.message}"
      change_gem_version(prev_version)
      bundler_rollback
      raise e
    end

    # FIXME: The response does not hint to success/failure of the restart. Investigate whether we can use Thread.new or
    # otherwise wait for a response while still ensuring that the Rails app is restarted before validating the result.
    Thread.new do
      System.restart_application
      ActiveRecord::Base.connection.close
    end
  end

  # Uninstalls an extension gem.
  def uninstall_gem
    setup_instance

    begin
      remove_from_gemfile
      Terrapin::CommandLine.new('bundle', 'clean').run
    rescue StandardError => e
      Rails.logger.error "Error in post-uninstall of #{@gem}: #{e.message}"
      inject_gem
    end

    # TODO: implement service de-registration

    # FIXME: Do we need to restart if the gem constants are not called anymore?
    Thread.new do
      restart_successful = System.restart_application
      # Re-add the gem so that Gemfile and installation state are consistent.
      inject_gem unless restart_successful
      ActiveRecord::Base.connection.close
    end
  end

  def uninstall_without_restart
    setup_instance
    remove_from_gemfile
    post_uninstall
    # TODO: implement service de-registration and other cleanup
  end

  def post_install
    setup_instance
    engine = "#{@gem.camelize}::Engine".safe_constantize
    return if engine.config.paths['db/migrate'].existent.empty?

    Terrapin::CommandLine.new('bin/rails', "#{@gem}:install:migrations").run
    Terrapin::CommandLine.new('bin/rails', "db:migrate SCOPE=#{@gem}").run
    engine.load_seed
  rescue RuntimeError, Terrapin::CommandLineError => e
    Rails.logger.error "Error during #{@gem} post-install: #{e.message}"
    raise e
    # TODO: Service registration or additional hooks once implemented and/or required
  end

  def post_update
    setup_instance
    engine = "#{@gem.camelize}::Engine".safe_constantize
    return if engine.config.paths['db/migrate'].existent.empty?

    Terrapin::CommandLine.new('bin/rails', "#{@gem}:install:migrations").run
    Terrapin::CommandLine.new('bin/rails', "db:migrate SCOPE=#{@gem}").run
  rescue RuntimeError, Terrapin::CommandLineError => e
    Rails.logger.error "Error during #{@gem} post-update: #{e.message}"
    raise e
    # TODO: Service registration or additional hooks once implemented and/or required
  end

  def post_uninstall
    setup_instance
    Terrapin::CommandLine.new('bin/rails', 'db:migrate SCOPE=:gem VERSION=0').run(gem: @gem)
    Pathname.glob("db/migrate/*.#{@gem}.rb").each(&:delete)
  end

  private

  # Sets up the instance variables after validation.
  def setup_instance
    @extension_type = self.class.name.downcase
    unless EXTENSION_TYPES.include?(@extension_type)
      raise JSONAPI::Exceptions::InvalidResource
    end

    @gem = name
    @version = version
    unless Gem::Version.correct?(@version)
      raise JSONAPI::Exceptions::InvalidResource
    end
    # TODO: Verify that gem name conforms to gem naming conventions (lowercase letters + underscore)
  end

  def inject_gem
    line = Terrapin::CommandLine.new('bundle', 'add :gem --source=:source --group=:group --skip-install')
    line.run(gem: @gem, source: download, group: "#{@extension_type},manual")
  end

  # Removes this instance's @gem from Gemfile.
  def remove_from_gemfile
    # TODO: Can we check if the gem was added at all, so that we don't get an error if its not there?
    Bundler::Injector.remove([@gem], 'install' => true)
  rescue Bundler::GemfileError => e
    Rails.logger.error e.message
  ensure
    definition = Bundler::Definition.build(Bundler.default_gemfile, Bundler.default_lockfile, nil)
    definition.lock(Bundler.default_lockfile)
  end

  def change_gem_version(version)
    search = /gem "#{@gem}", "= [0-9].[0-9].[0-9]"/
    replace = "gem \"#{@gem}\", \"= #{version}\""
    gemfile_path = Rails.root.join('Gemfile')

    tmp = Tempfile.new(%w[Gemfile .tmp], Rails.root.join('tmp'))
    tmp.write(File.read(gemfile_path).dup.gsub(search, replace))
    tmp.rewind
    FileUtils.copy(tmp, gemfile_path)
    tmp.close!
  end

  # Rolls all bundler operations back to the previous state.
  def bundler_rollback
    rt = new_runtime
    rt.lock
    rt.clean
  end

  # Resets the Bundler runtime to ensure that the Gemfile specs are loaded.
  # Unfortunately, this has no effect on Rubygems
  # or $LOAD_PATH / $LOADED_FEATURES, but at least deals with Bundler inconsistencies.
  def refresh_runtime
    Bundler.reset!
    Bundler.require(*Rails.groups, *EXTENSION_TYPES)
  rescue Bundler::GemRequireError => e
    bundler_rollback
    raise e
  end

  # Generates a new Bundler::Runtime whose definition is re-read from the Gemfile.
  def new_runtime
    Bundler::Runtime.new(Bundler.root, new_definition)
  end

  # Generates a new Definition from the Gemfile and Lockfile. Ensures that there is no cached Definition.
  # @param [Hash, Boolean, nil] unlock Gems that have been requested to be updated or true if all gems should be updated
  # @return [Bundler::Definition]
  def new_definition(unlock = nil)
    Bundler::Definition.build(Bundler.default_gemfile, Bundler.default_lockfile, unlock)
  end

  # Checks whether the given extension resource is properly installed.
  # @param [String] gem The gem name that should be checked.
  # @param [String] version The version which should be installed.
  def installed?(gem, version)
    gem_present = Gem.loaded_specs.keys.any?(gem)
    if gem_present
      Gem.loaded_specs[gem].version == Gem::Version.new(version)
    else
      gem_present
    end
  end

  def bundler_options
    { without: Rails.env.production? ? %w[development test] : ['production'], jobs: 5 }
  end
end
