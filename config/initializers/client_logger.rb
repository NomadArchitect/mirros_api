# frozen_string_literal: true

require 'singleton'

# Custom Client logger
class ClientLogger < Logger
  include Singleton

  def initialize
    super(Rails.root.join('log', 'clients.log'))
    self.formatter = formatter
    self
  end

  # Optional, but good for prefixing timestamps automatically
  def formatter
    proc { |severity, time, _progname, msg|
      formatted_severity = format('%-5s', severity.to_s)
      formatted_time = time.strftime('%Y-%m-%d %H:%M:%S')
      "[#{formatted_severity} #{formatted_time}] #{msg}\n"
    }
  end

  class << self
    delegate :error, :debug, :fatal, :info, :warn, :add, :log, to: :instance
  end
end
