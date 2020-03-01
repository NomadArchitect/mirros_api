# frozen_string_literal: true

module NetworkManager
  require 'English'
  class Logger < ::Logger
    class << self
      attr_accessor :logger
      delegate :info, :warn, :debug, :error, to: :logger
    end

    def formatter
      proc { |severity, time, _progname, msg|
        formatted_severity = format("%-5s", severity.to_s)
        formatted_time = time.strftime('%Y-%m-%d %H:%M:%S')
        "[#{formatted_severity} #{formatted_time} #{$PROCESS_ID}]\n #{msg}\n"
      }
    end
  end
end
