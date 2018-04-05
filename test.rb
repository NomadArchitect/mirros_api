require 'bundler/setup'
require 'bundler/dependency'
require 'bundler/injector'

dep = Bundler::Dependency.new('netatmo', '0.1.0', {'source': 'http://gems.marco-roth.ch'})
injector = Bundler::Injector.new([dep])
injector.inject(File.absolute_path('Gemfile.local'), File.absolute_path('Gemfile.local.lock'))
#system('bundle inject netatmo --source=http://gems.marco-roth.ch')
#system('bundle update netatmo')
