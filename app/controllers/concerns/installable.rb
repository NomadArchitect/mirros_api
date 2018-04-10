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
    # Bundler.injector needs a string-keyed option hash.
    options = {'source' => engine['download'], 'group' => @extension_type}

    begin
      dep = Bundler::Dependency.new(@gem, @version, options)
      injector = Bundler::Injector.new([dep])

      # Injector._append_to expects Pathname objects instead of path strings.
      local_gemfile = Pathname.new(File.absolute_path('Gemfile.local'))
      lockfile = Pathname.new(File.absolute_path('Gemfile.lock'))
      new_deps = injector.inject(local_gemfile, lockfile)

    rescue Bundler::Dsl::DSLError => e
      bundler_error(e)
    end

    installer = Bundler::Installer.new(Bundler.root, Bundler.definition)
    installer.run({})

    # TODO: Validate @model against downloaded extension info (TBD)
    require_type
    # TODO: Service registration etc.
  end

  # Checks whether the given extension resource is properly installed.
  def installed?
    Gem.loaded_specs.keys.any?(@model.attributes['name'])
  end

  def uninstall
    determine_type
    engine = @model.attributes
    @gem = engine['name']
    uninstall_gem
    # TODO: implement service de-registration and other cleanup
  end

  def update
    # Bundle update
    determine_type
    engine = @model.attributes

    search = /gem "#{engine['name']}", "= [0-9].[0-9].[0-9]"/
    replace = "gem \"#{engine['name']}\", \"= #{engine['version']}\""

    tmp = Tempfile.new(['Gemfile.local', '.tmp'], Rails.root.to_s + '/tmp')
    tmp.write(File.read(Rails.root.to_s + '/Gemfile.local').dup.gsub(search, replace))
    tmp.rewind
    FileUtils.copy(tmp, Rails.root.to_s + "/Gemfile.local")
    tmp.close!

    installer = Bundler::Installer.new(Bundler.root, Bundler.definition)
    installer.run({})

    require_type
    # TODO: service re-registration etc. necessary?
  end

  private

  # Ensure that this module is only used on classes that can actually be installed.
  def determine_type
    @extension_type = self.class.name.downcase.sub('resource', '')
    raise JSONAPI::Exceptions::InvalidResource unless EXTENSION_TYPES.include?(@extension_type)
  end

  def uninstall_gem
    # Bundler has no remove method yet, so we need to manually remove the gem's line from the Gemfile.
    search_text = /gem "#{@gem}"/
    tmp = Tempfile.new(['Gemfile.local', '.tmp'])

    File.open("Gemfile.local", 'r') do |file|
      file.each_line do |line|
        tmp.write(line) unless line =~ search_text || line =~ /#/
      end
    end

    tmp.rewind
    FileUtils.copy(tmp, "Gemfile.local")
    tmp.close!

    # Once the extension gem is removed, clear its dependencies if they are no longer required (eq. `bundle clean`)
    extensions = Bundler.setup(@extension_type)
    extensions.clean
  end

  # @param [Object] error An optional Error object that has the methods message and status_code.
  def bundler_error(error = nil)
    uninstall_gem(@gem) # Roll back changes made to Gemfile.local
    msg = "Error while installing extension #{@gem})"
    msg += error.nil? ? ": #{error.message}, code: #{error.status_code}" : ""
    raise JSONAPI::Exceptions::InternalServerError.new(msg)
  end

  def require_type
    begin
      # Installed extensions are scoped by group. Reload just this group instead of all gems.
      Bundler.require(@extension_type)
    rescue Bundler::LoadError => e
      bundler_error(e)
    end
  end

end
