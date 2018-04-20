# frozen_string_literal: true
require 'bundler/setup'
require 'bundler/dependency'
require 'bundler/injector'
require 'bundler/installer'
require 'pathname'
require 'tempfile'

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
  end

  # Update the extension to the passed version.
  def update
    setup_instance

    prev_version = Bundler.definition.specs.[](@gem).first.version.to_s # Save previous version in case we need to reset.
    change_gem_version(@version)

    begin
      options = {'without' => 'development', 'jobs' => 5}
      installer = Bundler::Installer.install(Bundler.root, new_definition(:gems => ['netatmo']), options)
    rescue Bundler::BundlerError => e
      change_gem_version(prev_version)
      raise bundler_error(e)
    end

    # FIXME: The response does not hint to success/failure of the restart. Investigate whether we can use Thread.new or
    # otherwise wait for a response while still ensuring that the Rails app is restarted before validating the result.
    fork {
      restart = system("rails restart")

      unless restart === true
        change_gem_version(prev_version)
        system("rails restart") # Restart a second time with the old gem version which should be installed.
      end
    }
  end

  # Uninstalls an extension gem.
  def uninstall
    setup_instance
    remove_from_gemfile

    fork {
      restart = system("rails restart")

      if restart != true
        inject_gem # Re-add the gem so that Gemfile and installation state are consistent.
      end
    }

    # TODO: implement service de-registration and other cleanup
  end


  private

  # Sets up the instance variables after validation.
  def setup_instance
    @extension_type = self.class.name.downcase.sub('resource', '')
    raise JSONAPI::Exceptions::InvalidResource unless EXTENSION_TYPES.include?(@extension_type)

    @engine = @model.attributes
    # CAUTION: ActiveRecord.attributes() returns a hash with string keys, not symbols!
    @gem, @version = @engine['name'], @engine['version']
    # TODO: Verify that version conforms to SemVer, gem name conforms to gem naming conventions (lowercase letters + underscore)
  end

  def inject_gem
    options = {'source' => @engine['download'], 'group' => @extension_type} # Injector uses a string-keyed option hash.
    # TODO: Validate @model against downloaded extension info (TBD)

    begin
      dep = Bundler::Dependency.new(@gem, @version, options)
      injector = Bundler::Injector.new([dep])

      # Injector._append_to expects Pathname objects instead of path strings.
      gemfile = Pathname.new(File.absolute_path('Gemfile'))
      lockfile = Pathname.new(File.absolute_path('Gemfile.lock'))

      new_deps = injector.inject(gemfile, lockfile)

    rescue Bundler::Dsl::DSLError => e
      bundler_error(e)
    end
  end

  # Removes this instance's @gem from Gemfile. Bundler has no remove method yet, so we need to search/replace.
  def remove_from_gemfile
    search_text = /gem "#{@gem}"/
    tmp = Tempfile.new(['Gemfile', '.tmp'])

    File.open(Bundler.default_gemfile, 'r') do |file|
      file.each_line do |line|
        tmp.write(line) unless line =~ search_text || line =~ /# Added/ || line =~ /^\n$/ # Removes autogenerated lines
      end
    end
    tmp.rewind # Otherwise the pointer is at the end and nothing gets copied.
    FileUtils.copy(tmp, Bundler.default_gemfile)
    tmp.close!
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
    msg += error.nil? ? "#{error.message}, code: #{error.status_code}" : "Gem not in loaded specs"
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
