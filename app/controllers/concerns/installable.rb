# frozen_string_literal: true

require 'zip'
require 'fileutils'

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
    res = download_extension(engine['download'])
    extract_zip(engine['name'], res)
  end

  def installed?
    engine = @model.attributes
    File.file?("engines/#{engine['name']}")
  end

  def uninstall
    engine = @model.attributes
    # TODO: implement service de-registration and other cleanup
    FileUtils.rm_rf("engines/#{engine['name']}")

  end

  def update
    # TODO: implement
    'not implemented'
    # download_extract_zip(['download'], engine['name'])
  end

  private

  # Ensure that this module is only used on classes that can actually be
  # installed.
  def determine_type
    @extension_type = self.class.name.downcase.sub('resource', '')
    raise JSONAPI::Exceptions::InvalidResource unless EXTENSION_TYPES.include?(@extension_type)
  end

  def download_extension(uri)
    res = HTTParty.get(uri)
    if res.code != 200 # HTTParty follows redirects by default
      raise JSONAPI::Exceptions::InvalidFieldValue.new('download', uri)
    end
    res.parsed_response
  rescue HTTParty::Error => e
    raise JSONAPI::Exceptions::InternalServerError.new(e.message), e.message
  end

  def extract_zip(filename, contents)
    tmp_file = Tempfile.new(filename)
    tmp_file.binmode.write(contents)
    tmp_file.close

    # TODO: Catch errors from ZIP extraction (apart from overwrite)
    Zip::File.open(tmp_file.path) do |zip_file|
      zip_file.each do |entry|
        # Overwrite existing files instead of err'ing
        entry.extract("engines/#{entry.name}") { true }
      end
    end
    tmp_file.unlink
  end

end

