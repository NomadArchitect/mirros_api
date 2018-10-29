require_relative '../../app/controllers/concerns/installable'

namespace :extension do
  desc "Add/update/remove an extension in the DB without running the model callbacks"

  task :insert, %i[type extension] => [:environment] do |task, args|

    next unless arguments_valid?(args)

    spec = Gem::Specification.load("#{Rails.root}/#{args[:type]}s/#{args[:extension]}/#{args[:extension]}.gemspec")
    meta = JSON.parse(spec.metadata['json'], symbolize_names: true)

    next unless spec_valid?(args[:type], spec, meta)

    extension_class = args[:type].capitalize.safe_constantize
    extension_class.skip_callback :create, :after, :install

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


    extension_class.create!({
                              name: spec.name,
                              title: meta[:title],
                              description: meta[:description],
                              version: spec.version.to_s,
                              creator: spec.author,
                              homepage: spec.homepage,
                              download: 'http://my-gemserver.local',
                            }.merge(type_specifics)
    )

    puts "Inserted #{args[:type]} #{extension_class.find(spec.name)} into the #{Rails.env} database"
    extension_class.set_callback :create, :after, :install
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

  def spec_valid?(type, spec, meta)
    if type.to_sym.equal? :source
      if meta[:groups].empty?
        puts 'Sources must specify at least one group for which they provide data.'
        return false
      end
    end
    true
  end
end
