# frozen_string_literal: true

require_relative '../../app/lib/extension_parser'

namespace :extensions do
  desc 'installs all available migrations for the bundled extensions'
  task install_migrations: [:environment] do
    defaults = Bundler.load.current_dependencies.select { |dep| dep.groups.any?(/widget|source/) }
    defaults.each do |ext|
      if Pathname.new("#{ext.to_spec.full_gem_path}/db/migrate").exist?
        command = ENV['SNAP'].nil? ? 'rails' : '"$SNAP/wrapper" "$SNAP/api/bin/rails"'
        `#{command} #{ext.name}:install:migrations`
      end
    end
  end
end

namespace :extension do
  # FIXME: Can we offload the parser initialization + validity check to a setup task?

  desc 'insert an extension into the DB'
  task :insert, %i[extension_name] => [:environment] do |_task, args|
    parser = parser_for_gem args[:extension_name]

    unless parser.meta_valid?
      puts 'Sources must specify at least one group for which they provide data.'
      next
    end

    klass = parser.extension_class
    klass.create!(parser.extension_attributes)
    
    puts "Inserted #{klass} #{klass.find(parser.internal_name)} into the #{Rails.env} database"
  end

  desc 'update an extension in the DB'
  task :update, %i[extension_name] => [:environment] do |_task, args|
    # FIXME: Add migration logic to upgrade existing extensions without the namespace!

    parser = parser_for_gem args[:extension_name]

    unless parser.meta_valid?
      puts 'Sources must specify at least one group for which they provide data.'
      next
    end

    klass = parser.extension_class
    
    record = klass.find_by(slug: parser.internal_name)
    if record.nil?
      raise ArgumentError, "Couldn't find #{klass} #{parser.internal_name} in the #{Rails.env} db"
    end
    record.update!(parser.extension_attributes)
    
    puts "Updated #{klass} #{klass.find(parser.internal_name)} in the #{Rails.env} database"
  end

  desc 'remove an extension from the DB'
  task :remove, %i[extension_name] => [:environment] do |_task, args|

    unless Gem.loaded_specs['bundler'].version >= Gem::Version.new('1.17.0')
      puts 'Please upgrade your bundler installation to 1.17.0 or later to run this task.'
      next
    end
    parser = parser_for_gem args[:extension_name]
    record = parser.extension_class.find_by(slug: parser.internal_name)
    record.delete

    puts "Removed #{parser.extension_class} #{parser.internal_name} from the #{Rails.env} database"

    Bundler::Injector.remove([parser.gem_name])
  rescue Bundler::GemfileError => e
    puts e.message
  end

  def parser_for_gem(gem_name)
    spec = load_spec gem_name
    ExtensionParser.new spec
  end

  # Retrieves the loaded gem specification for a given gem name.
  # @return [Gem::Specification] The loaded Gem specification.
  # @raise [ArgumentError] if no spec for the given gem name is present in the loaded Bundler dependencies.
  def load_spec(gem_name)
    dependency = Gem.loaded_specs[gem_name]
    if dependency.nil?
      raise ArgumentError, "Could not find a Gem dependency for gem #{gem_name}"
    end
    dependency
  end

end
