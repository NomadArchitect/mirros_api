require "bundler/inline"

module MirrOS
  module Source

    def Source.load_sources(source = "")

      base = "engines"

      begin
        gemfile(true) do
          if source.empty?
            sources = Dir.glob("#{base}/*")

            sources.each do |e|
              gem e.gsub("#{base}/", ""), path: e
            end

          else
            gem source, path: "#{base}/#{source}"
          end
        end
      rescue
        puts "Source '#{source}' could not be loaded or found"
      end
    end

    def Source.install
      # TODO: implement
      "not implemented"
    end

    def Source.update
      # TODO: implement
      "not implemented"
    end

    def Source.remove
      # TODO: implement
      "not implemented"
    end

    def Source.list
      # TODO: implement
      "not implemented"
    end

  end
end
