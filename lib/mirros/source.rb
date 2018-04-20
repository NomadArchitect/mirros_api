require "bundler/inline"
require "fileutils"

module MirrOS
  module Source

    BASE = "engines"

    def Source.load_sources(source = "")

      sources = Dir.glob("#{BASE}/*")

      unless sources.count == 0
        begin
          gemfile(true) do
            if source.empty?
              sources.each do |e|
                gem e.gsub("#{BASE}/", ""), path: e
              end
            else
              gem source, path: "#{BASE}/#{source}"
            end
          end
        rescue
          puts "Source '#{source}' could not be loaded or found"
        end
      else
        puts "No sources found in '#{BASE}'"
      end
    end

    def Source.install(user = "marcoroth", repo = "mirrOS_netatmo", host = "github.com")

      begin
        g = Git.clone("git@#{host}:#{user}/#{repo}.git", repo, path: BASE)
      rescue Exception => e
        puts "Source '#{repo}' could not be installed"
        puts "Error: #{e}"
      end

      Source.load_sources
    end

    def Source.update(source)
      unless source.nil? || source.empty?
        begin
          Git.open("#{BASE}/#{source}").pull
        rescue Exception => e
          puts "Source '#{repo}' could not be updated"
          puts "Error: #{e}"
        end
      end

      Source.load_sources
    end

    def Source.remove(source)

      unless source.nil? || source.empty?
        begin
          FileUtils.rm_rf(dir)
        rescue Exception => e
          puts "Source '#{repo}' could not be removed"
          puts "Error: #{e}"
        end
      end

      Source.load_sources
    end

    def Source.list
      # TODO: implement
      "not implemented"
    end

  end
end
