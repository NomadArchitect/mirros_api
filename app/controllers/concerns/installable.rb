# frozen_string_literal: true
require 'bundler/setup'
require 'bundler/dependency'
require 'bundler/injector'
require 'bundler/installer'
require 'bundler/lockfile_generator'
require 'pathname'

# Provides methods to install, update and uninstall widgets and sources.
module Installable

  EXTENSION_TYPES = %w[widget source].freeze

  def install
    setup_instance

    begin
      inject_gem
      options = {'jobs' => 5, 'without' => 'development'}
      installer = Bundler::Installer.new(Bundler.root, Bundler.definition)
      installer.run(options)
    rescue Bundler::BundlerError, Net::HTTPError => e
      remove_from_gemfile
      raise bundler_error(e)
    end

    refresh_runtime

    unless installed?(@gem, @version)
      remove_from_gemfile
      raise bundler_error
    end

    # TODO: Service registration etc if not possible through Engine functionality.
    # MirrOSApi::Application.load_tasks
    # Rake::Task["#{@gem}:install:migrations"].invoke
    # Rake::Task["db:migrate SCOPE=#{@gem}"].invoke
    # engine = "#{@gem}::Engine".safe_constantize
    # Thread.new do
    # engine.load_seed
    #   ActiveRecord::Base.connection.close
    # end
    #
  end

  # Update the extension to the passed version.
  def update
    setup_instance

    prev_version = Bundler.definition.specs.[](@gem).first.version.to_s # Save previous version in case we need to reset.
    change_gem_version(@version)

    begin
      options = {'without' => %w[development test], 'jobs' => 5}
      Bundler::Installer.install(Bundler.root,
                                 new_definition(gems: [@gem]),
                                 options)
    rescue Bundler::BundlerError => e
      change_gem_version(prev_version)
      raise bundler_error(e)
    end

    # FIXME: The response does not hint to success/failure of the restart. Investigate whether we can use Thread.new or
    # otherwise wait for a response while still ensuring that the Rails app is restarted before validating the result.
    fork do
      restart_successful = System.restart_application

      unless restart_successful
        change_gem_version(prev_version)
        # Restart a second time with the old gem version which should be installed.
        System.restart_application
      end
    end
  end

  # Uninstalls an extension gem.
  def uninstall
    setup_instance
    remove_from_gemfile
    # TODO: implement service de-registration and other cleanup
    # db:migrate SCOPE=gemname VERSION=0
    # File.delete(db/migrate/???)

    fork do
      restart_successful = System.restart_application

      # Re-add the gem so that Gemfile and installation state are consistent.
      inject_gem unless restart_successful

    end
  end

  def uninstall_without_restart
    setup_instance
    remove_from_gemfile
    # TODO: implement service de-registration and other cleanup
  end


  private

  # Sets up the instance variables after validation.
  def setup_instance
    @extension_type = self.class.name.downcase
    raise JSONAPI::Exceptions::InvalidResource unless EXTENSION_TYPES.include?(@extension_type)

    @gem = name
    @version = version
    # TODO: Verify that version conforms to SemVer, gem name conforms to gem naming conventions (lowercase letters + underscore)
  end

  def inject_gem
    # Injector uses a string-keyed option hash.
    options = {'source' => download, 'group' => [@extension_type]}
    # TODO: Validate @model against downloaded extension info (TBD)

    begin
      dep = Bundler::Dependency.new(@gem, @version, options)
      injector = Bundler::Injector.new([dep])

      # Injector._append_to expects Pathname objects instead of path strings.
      gemfile = Pathname.new(File.absolute_path('Gemfile'))
      lockfile = Pathname.new(File.absolute_path('Gemfile.lock'))

      injector.inject(gemfile, lockfile)

    rescue Bundler::Dsl::DSLError => e
      bundler_error(e)
    end
  end

  # Removes this instance's @gem from Gemfile.
  def remove_from_gemfile
    Bundler::Injector.remove([@gem], 'install' => true)
    definition = Bundler::Definition.build(Bundler.default_gemfile, Bundler.default_lockfile, nil)
    definition.lock(Bundler.default_lockfile)
  end

  def change_gem_version(version)
    search = /gem "#{@gem}", "= [0-9].[0-9].[0-9]"/
    replace = "gem \"#{@gem}\", \"= #{version}\""

    tmp = Tempfile.new(['Gemfile', '.tmp'], Rails.root.to_s + '/tmp')
    tmp.write(File.read(Rails.root.to_s + '/Gemfile').dup.gsub(search, replace))
    tmp.rewind
    FileUtils.copy(tmp, Rails.root.to_s + "/Gemfile")
    tmp.close!
  end

  # Cleans up the bundle and raises an exception in case there is an error during Bundler operations.
  # @param [Object] error An optional Error object that has the methods message and status_code.
  def bundler_error(error = nil)
    rt = new_runtime
    rt.lock
    rt.clean
    msg = "Error while installing extension #{@gem}: "
    msg += error.nil? ? "Gem not in loaded specs" : "#{error.message}, code: #{error.status_code}"
    raise StandardError.new(msg)
  end

  # Resets the Bundler runtime to ensure that the Gemfile specs are loaded. Unfortunately, this has no effect on Rubygems
  # or $LOAD_PATH / $LOADED_FEATURES, but at least deals with Bundler inconsistencies.
  def refresh_runtime
    begin
      Bundler.reset!
      Bundler.require(*Rails.groups, *EXTENSION_TYPES)
    rescue Bundler::GemRequireError => e
      bundler_error(e)
    end
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
      Gem.loaded_specs[gem].version === Gem::Version.new(version)
    else
      gem_present
    end
  end

end
