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
    determine_type
    # CAUTION: ActiveRecord.attributes() returns a hash with string keys, not symbols!
    engine = @model.attributes
    @gem, @version = engine['name'], engine['version']
    options = {'source' => engine['download'], 'group' => @extension_type} # Injector uses a string-keyed option hash.
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

    installer = Bundler::Installer.new(Bundler.root, Bundler.definition)
    installer.run({'jobs' => 5})

    refresh_runtime

    puts "#{@gem} #{@version} is installed: #{installed?(@gem, @version)}"
    # TODO: Service registration etc.
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

  # Update the extension gem's version in the Gemfile. Bundler currently has no clean way to do this.
  def update
    determine_type
    engine = @model.attributes

    search = /gem "#{engine['name']}", "= [0-9].[0-9].[0-9]"/
    replace = "gem \"#{engine['name']}\", \"= #{engine['version']}\""

    tmp = Tempfile.new(['Gemfile', '.tmp'], Rails.root.to_s + '/tmp')
    tmp.write(File.read(Rails.root.to_s + '/Gemfile').dup.gsub(search, replace))
    tmp.rewind
    FileUtils.copy(tmp, Rails.root.to_s + "/Gemfile")
    tmp.close!

    installer = Bundler::Installer.new(Bundler.root, new_definition)
    installer.run({'jobs' => 5})

    refresh_runtime
    puts "#{@gem} #{@version} is installed: #{installed?(@gem, @version)}"

    # TODO: service re-registration etc. necessary?
  end
  def uninstall
    determine_type
    engine = @model.attributes
    @gem = engine['name']
    puts "#{@gem} #{engine['version']} is installed: #{installed?(@gem, engine['version'])}"

    remove_gem

    rt = new_runtime
    rt.lock
    rt.clean
    refresh_runtime
    puts "#{@gem} #{engine['version']} is installed: #{installed?(@gem, engine['version'])}"
    # TODO: implement service de-registration and other cleanup
  end



  private

  # Ensure that this module is only used on classes that can actually be installed.
  def determine_type
    @extension_type = self.class.name.downcase.sub('resource', '')
    raise JSONAPI::Exceptions::InvalidResource unless EXTENSION_TYPES.include?(@extension_type)
  end

  def remove_gem
    # Bundler has no remove method yet, so we need to manually remove the gem's line from the Gemfile.
    search_text = /gem "#{@gem}"/
    tmp = Tempfile.new(['Gemfile', '.tmp'])

    File.open(Bundler.default_gemfile, 'r') do |file|
      file.each_line do |line|
        tmp.write(line) unless line =~ search_text || line =~ /# Added/ || line =~/^\n$/
      end
    end

    tmp.rewind
    FileUtils.copy(tmp, Bundler.default_gemfile)
    tmp.close!
  end

  # @param [Object] error An optional Error object that has the methods message and status_code.
  def bundler_error(error = nil)
    remove_gem # Roll back changes made to Gemfile_extensions
    clean_bundle
    msg = "Error while installing extension #{@gem})"
    msg += error.nil? ? ": #{error.message}, code: #{error.status_code}" : ""
    raise JSONAPI::Exceptions::InternalServerError.new(msg)
  end

  def refresh_runtime
    begin
      # Installed extensions are scoped by group. Reload just this group instead of all gems.
      new_runtime.require(*Rails.groups, @extension_type)
        #Bundler.require(@extension_type)
    rescue Bundler::GemRequireError => e
      bundler_error(e)
    end
  end

  def new_runtime
    Bundler::Runtime.new(Bundler.root, new_definition)
  end

  def new_definition
    Bundler::Definition.build(Bundler.default_gemfile, Bundler.default_lockfile, nil)
  end

end
