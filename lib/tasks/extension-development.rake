require_relative '../../app/controllers/concerns/installable'

namespace :extension do
  desc "Add/update/remove an extension in the DB without running the model callbacks"

  task :insert, %i[type extension] => [:environment] do |task, args|

    next unless arguments_valid?(args)

    spec = load_spec(args)
    meta = parse_meta(spec)

    next unless spec_valid?(args[:type], spec, meta)

    extension_class = args[:type].capitalize.safe_constantize
    extension_class.skip_callback :create, :after, :install
    extension_class.create!(construct_attributes(args, spec, meta))
    puts "Inserted #{args[:type]} #{extension_class.find(spec.name)} into the #{Rails.env} database"
    extension_class.set_callback :create, :after, :install
  end

  task :update, %i[type extension] => [:environment] do |task, args|
    next unless arguments_valid?(args)

    spec = load_spec(args)
    meta = parse_meta(spec)

    next unless spec_valid?(args[:type], spec, meta)

    extension_class = args[:type].capitalize.safe_constantize
    extension_class.skip_callback :update, :after, :update
    record = extension_class.find_by(slug: args[:extension])
    record.update!(construct_attributes(args, spec, meta))
    puts "Updated #{args[:type]} #{extension_class.find(spec.name)} in the #{Rails.env} database"
    extension_class.set_callback :update, :after, :update
  end


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

  task :remove, %i[type extension] => [:environment] do |task, args|
    next unless arguments_valid?(args)

    unless Gem.loaded_specs['bundler'].version >= Gem::Version.new('1.17.0')
      puts 'Please upgrade your bundler installation to 1.17.0 or later to run this task.'
      next
    end

    extension_class = args[:type].capitalize.safe_constantize
    extension_class.skip_callback :destroy, :before, :uninstall
    extension_class.create!(construct_attributes(args, spec, meta))
    puts "Inserted #{args[:type]} #{extension_class.find(spec.name)} into the #{Rails.env} database"
    extension_class.set_callback :destroy, :before, :uninstall

    Bundler::Injector.remove([args[:extension]])
  end

  # Helpers
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
    Gem::Specification.load("#{Rails.root}/#{args[:type]}s/#{args[:extension]}/#{args[:extension]}.gemspec")
  end

  def parse_meta(spec)
    JSON.parse(spec.metadata['json'], symbolize_names: true)
  end

  def construct_attributes(args, spec, meta)
    type_specifics = if args[:type].to_sym.equal? :widget
                       attrs = {
                         icon: "http://backend-server.tld/icons/#{spec.name}.svg",
                         languages: meta[:languages]
                       }
                       if meta[:group].nil?
                         attrs
                       else
                         attrs.merge({group_id: Group.find_by(name: meta[:group])})
                       end
                     else
                       {
                         groups: meta[:groups].map {|g| Group.find_by(name: g)}
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
