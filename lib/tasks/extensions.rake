require_relative '../../app/models/concerns/installable'

namespace :extension do
  desc 'insert an extension into the DB'
  task :insert, %i[type extension mode] => [:environment] do |task, args|
    unless args[:mode].eql?('seed')
      next unless arguments_valid?(args)
    end

    spec = load_spec(args)
    meta = parse_meta(spec)

    unless args[:mode].eql?('seed')
      next unless spec_valid?(args[:type], spec, meta)
    end

    extension_class = args[:type].capitalize.safe_constantize
    extension_class.create!(construct_attributes(args, spec, meta))
    puts "Inserted #{args[:type]} #{extension_class.find(spec.name)} into the #{Rails.env} database"
  end

  desc 'update an extension in the DB'
  task :update, %i[type extension mode] => [:environment] do |task, args|

    unless args[:mode].eql?('seed')
      next unless arguments_valid?(args)
    end

    spec = load_spec(args)
    meta = parse_meta(spec)

    unless args[:mode].eql?('seed')
      next unless spec_valid?(args[:type], spec, meta)
    end

    extension_class = args[:type].capitalize.safe_constantize
    record = extension_class.find_by(slug: args[:extension])

    if record.nil?
      raise ArgumentError, "#{args[:type]} #{args[:extension]} not present in the #{Rails.env} db"
    end

    record.update!(construct_attributes(args, spec, meta))
    puts "Updated #{args[:type]} #{extension_class.find(spec.name)} in the #{Rails.env} database"
  end

  desc 'remove an extension from the DB'
  task :remove, %i[type extension] => [:environment] do |task, args|
    next unless arguments_valid?(args)

    unless Gem.loaded_specs['bundler'].version >= Gem::Version.new('1.17.0')
      puts 'Please upgrade your bundler installation to 1.17.0 or later to run this task.'
      next
    end

    extension_class = args[:type].capitalize.safe_constantize
    record = extension_class.find_by(slug: args[:extension])
    record.destroy!
    puts "Removed #{args[:type]} #{args[:extension]} from the #{Rails.env} database"

    Bundler::Injector.remove([args[:extension]])
  end

  # Helpers
  def arguments_valid?(args)
    unless Installable::EXTENSION_TYPES.include?(args[:type])
      puts 'Type must be widget or source'
      return false
    end

    spec_path = "#{Rails.root}/#{args[:type]}s/#{args[:extension]}/#{args[:extension]}.gemspec"
    unless File.exist? spec_path
      puts "Could not find gemspec file at #{Rails.root}/#{args[:type]}s/#{args[:extension]}/#{args[:extension]}.gemspec\nCheck if you provided the correct extension name and if the gemspec file exists."
      return false
    end

    true
  end

  def spec_valid?(type, spec, meta)
    if type.to_sym.equal? :source
      if meta[:groups].empty?
        puts 'Sources must specify at least one group for which they provide data.'
        return false
      end
    end
    true
  end

  def load_spec(args)
    if args[:mode] == 'seed'
      path = `bin/bundle show #{args[:extension]}`
      parts = path.split('/')
      spec_file = "#{parts.slice(0..-3).join('/')}/specifications/#{parts.last.chomp!}.gemspec"
      Gem::Specification.load(spec_file)
    else
      Gem::Specification.load("#{Rails.root}/#{args[:type]}s/#{args[:extension]}/#{args[:extension]}.gemspec")
    end
  end

  def parse_meta(spec)
    JSON.parse(spec.metadata['json'], symbolize_names: true)
  end

  def construct_attributes(args, spec, meta)
    # FIXME: Use proper values if pulled from gemserver for seeding
    type_specifics = if args[:type].to_sym.equal? :widget
                       attrs = {
                         icon: "http://backend-server.tld/icons/#{spec.name}.svg",
                         sizes: meta[:sizes],
                         languages: meta[:languages],
                         single_source: meta[:single_source]
                       }
                       if meta[:group].nil?
                         attrs
                       else
                         attrs.merge({ group_id: Group.find_by(name: meta[:group]) })
                       end
                     else
                       {
                         groups: meta[:groups].map { |g| Group.find_by(name: g) }
                       }
                     end
    {
      name: spec.name,
      title: meta[:title],
      description: meta[:description],
      version: spec.version.to_s,
      creator: spec.author,
      homepage: spec.homepage,
      download: 'http://my-gemserver.local',
    }.merge(type_specifics)
  end
end
