ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require File.expand_path('../../lib/mirros/source.rb', __FILE__)
require File.expand_path('../../lib/mirros/widget.rb', __FILE__)
require File.expand_path('../../lib/mirros/system.rb', __FILE__)
