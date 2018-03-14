require "httparty"
require "fileutils"

module MirrOS
  module System

    def System.info
      # TODO: implement
      "not implemented"
    end

    # https://api.glancr.de/update/system/update.json
    # https://api.glancr.de/update/system/update.json.stable
    # https://api.glancr.de/update/system/update.json.beta
    def System.versions(branch = "stable")

      unless branch.nil? || branch.empty?
        begin
          url = "https://api.glancr.de/update/system/update.json.#{branch}"
          versions = JSON.load(open(url));

          puts "Available Versions on branch '#{branch}'"
          puts versions = versions.map {|v| v.first}
          return versions
        rescue Exception => e
          puts "Error while fetching data"
          puts "Error: #{e}"
        end
      else
        puts "Error: no branch set"
      end

      return []
    end

    # https://api.glancr.de/update/system/0.7.1.zip
    def System.update(version = "latest", branch = "stable")

      puts "Updating to Version '#{version}'..."

      if version == "latest"
        version = System.versions(branch).last
        puts "Version #{version} is the latest build..."
      end

      unless version.nil? || version.empty?
        begin
          system_url = "https://api.glancr.de/update/system/#{version}.zip"
          path = "tmp/#{version}.zip"
          extract_path = "tmp/#{version}"

          puts "Downloading image from Glancr to '#{path}'..."

          file = File.open(path, "wb")
          file.write(HTTParty.get(system_url).parsed_response)

          puts "Extracting image to '#{extract_path}'..."

          Zip::File.open(path) do |zip_file|
            zip_file.each do |entry|
              puts "Extracting #{entry.name}"
              entry.extract("#{extract_path}/#{entry.name}")
            end
          end

          FileUtils.rm_rf(path)

          puts "System updated to Version '#{version}'"
        rescue Exception => e
          puts "Error while updating System to Version '#{version}'"
          puts "Error: #{e}"
        end
      else
        puts "Error: no version specified"
      end

    end

    def System.reboot
      # TODO: implement
      "not implemented"
    end

    def System.shutdown
      # TODO: implement
      "not implemented"
    end

  end
end
