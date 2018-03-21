# frozen_string_literal: true

require 'zip'

# Provides methods to install, update and uninstall widgets and sources.
module Installable

  GLANCR_API_BASE = 'https://api.glancr.de'
  EXTENSION_TYPES = %w[widget source].freeze

  def install(engine_name, engine_version)
    # TODO: Print status to stdout if used via CLI
    # puts "installing a #{@type}"
    # puts "Downloading image from Glancr to '#{path}'..."
    # puts "Extracting image to '#{extract_path}'..."
    # puts "Extracting #{entry.name}"
    determine_type
    throw 'No engine name or version given' if engine_name.nil? || engine_version.nil?

    filename = "#{engine_name}-#{engine_version}.zip"
    engine_url = "#{GLANCR_API_BASE}/extensions/#{filename}"

    # TODO: Catch network errors from HTTParty
    tmp_zip = HTTParty.get(engine_url).parsed_response
    path = "tmp/#{filename}"

    begin
      file = File.open(path, 'wb')
      file.write(tmp_zip)
      file.close

      Zip::File.open(path) do |zip_file|
        zip_file.each do |entry|
          # Overwrite existing files instead of err'ing
          entry.extract("engines/#{entry.name}") { true }
        end
      end
    ensure
      File.unlink(file) unless file.nil?
    end
  end

  def uninstall(engine_name)
    # TODO: implement
    puts "not implemented, would uninstall #{engine_name}"
    File.unlink("engines/#{engine_name}")
  end

  def update
    # TODO: implement
    'not implemented'
  end


  # https://api.glancr.de/update/getVersions.php
  def list
    available_installables = HTTParty.get("#{GLANCR_API_BASE}/update/getVersions.php")
    JSON.parse(available_installables)
  end

  private

  # Ensure that this module is only used on classes that can actually be
  # installed.
  def determine_type
    @extension_type = self.class.name.downcase
    throw "can only install #{EXTENSION_TYPES}" unless EXTENSION_TYPES.include?(@extension_type)
  end
end

