# frozen_string_literal: true
require 'bundler/setup'
require 'bundler/dependency'
require 'bundler/injector'
require 'bundler/installer'
require 'pathname'
require 'tempfile'

#require 'zip'
#require 'fileutils'

# Provides methods to install, update and uninstall widgets and sources.
module Installable

  EXTENSION_TYPES = %w[widget source].freeze

  def install
    # TODO: Print status to stdout if used via CLI
    # puts "installing a #{@type}"
    # puts "Downloading image from Glancr to '#{path}'..."
    # puts "Extracting image to '#{extract_path}'..."
    # puts "Extracting #{entry.name}"
    determine_type
    # Get a copy of the model attributes, so we operate on the passed values.
    # CAUTION: ActiveRecord.attributes() returns a hash with string keys!
    engine = @model.attributes

    gem, version = engine['name'], engine['version']
    options = {'source' => engine['download']}
    puts "Generating dependency with #{gem}, version #{version} from #{options['source']}"

    begin
      dep = Bundler::Dependency.new(gem, version, options)
      injector = Bundler::Injector.new([dep])

      # Injector._append_to expects Pathname objects instead of path strings.
      local_gemfile = Pathname.new(File.absolute_path('Gemfile.local'))
      lockfile = Pathname.new(File.absolute_path('Gemfile.lock'))
      new_deps = injector.inject(local_gemfile, lockfile)

      puts "Added dependency #{new_deps} to #{local_gemfile}"
    rescue Bundler::Dsl::DSLError => e
      bundler_error(gem, e)
    end

    installer = Bundler::Installer.new(Bundler.root, Bundler.definition)
    installer.run({'gemfile': 'Gemfile.local'}) #.local

    begin
      Bundler.require # bundler_error(gem) unless
    rescue Bundler::LoadError => e
      bundler_error(gem, e)
    end

    # Gem.loaded_specs.keys.any?(gem)

    # TODO: Service registration etc.
    # TODO: Validate @model against downloaded extension info (TBD)
  end

  def installed?
    File.file?("engines/#{@model.attributes['name']}")
  end

  def uninstall
    determine_type
    engine = @model.attributes
    # TODO: implement service de-registration and other cleanup
    uninstall_gem(engine['name'])
  end

  def update
    # TODO: implement, basically the same as install but maybe diverging logic
    # for registrations etc.
    install
  end

  private

  # Ensure that this module is only used on classes that can actually be
  # installed.
  def determine_type
    @extension_type = self.class.name.downcase.sub('resource', '')
    raise JSONAPI::Exceptions::InvalidResource unless EXTENSION_TYPES.include?(@extension_type)
  end

  # @param [String] uri The full URI to the extension file
  # @return [Object] The parsed response body
  def download_extension(uri)
    res = HTTParty.get(uri)
    if res.code != 200 # HTTParty follows redirects by default
      raise JSONAPI::Exceptions::InvalidFieldValue.new('download', uri)
    end
    res.parsed_response
  rescue HTTParty::Error => e
    raise JSONAPI::Exceptions::InternalServerError.new(e.message), e.message
  end

  # @param [String] filename Name of the temporary file used by Tempfile.
  # @param [Object] contents Binary ZIP file object
  def extract_zip(filename, contents)
    tmp_file = Tempfile.new(filename)
    tmp_file.binmode.write(contents)
    tmp_file.close

    # TODO: Catch errors from ZIP extraction (apart from overwrite)
    Zip::File.open(tmp_file.path) do |zip_file|
      zip_file.each do |entry|
        # Overwrite existing files instead of err'ing
        # TODO: Specify sub-folder based on engine type?
        entry.extract("engines/#{entry.name}") { true }
      end
    end
    tmp_file.unlink
  end

  def uninstall_gem(gem)
    search_text = /gem "#{gem}"/
    tmp = Tempfile.new(['Gemfile.local', '.tmp'])
    File.open("Gemfile.local", 'r') do |file|
      file.each_line do |line|
        tmp.write(line) unless line =~ search_text || line =~ /#/
      end
    end
    tmp.rewind

    FileUtils.copy(tmp, "Gemfile.local")
    tmp.close!

    cleaner = Bundler.load
    cleaner.clean
  end

  def bundler_error(gem, error = nil)
    uninstall_gem(gem) # Roll back changes made to Gemfile.local
    msg = "Error while installing extension #{gem})"
    msg += error.nil? ? ": #{error.message}, code: #{error.status_code}" : ""
    raise JSONAPI::Exceptions::InternalServerError.new(msg)
  end

end
