require 'bundler/setup'
require 'bundler/dependency'
require 'bundler/injector'
require 'bundler/installer'
require 'pathname'

gem = "netatmo"
version = "0.1.1"
options = {'source' => 'http://localhost:9292'}

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
  bundler_error
end

if new_deps.first.equal?(gem)
  installer = Bundler::Installer.new(Bundler.root, Bundler.definition)
  installer.run({'gemfile': 'Gemfile.local'})

  require gem ? nil : bundler_error
else
  bundler_error
end

def bundler_error
  raise JSONAPI::Exceptions::InternalServerError.new(
      "Error while installing extension #{gem}: #{e.message}, code: #{e.status_code}")
end
