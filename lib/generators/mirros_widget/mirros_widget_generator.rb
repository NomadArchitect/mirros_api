require "rails/generators/rails/app/app_generator"

class MirrosWidgetGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  argument :name
  argument :fields, optional: true, type: :hash, default: {}

  def initialize_variables
    @fields = fields
    @path = "widgets/#{self.name}"
    @author_name = `git config --global user.name`.strip
    @author_email = `git config --global user.email`.strip

    o = []

    options.to_a.each do |name, state|
      o << "--#{name}" if state
      o << "--no-#{name}" unless state
    end

    @pass_options = o.join(" ")
  end

  def generate_plugin
    generate "plugin", "--mountable #{@path} #{@pass_options}"

    inject_into_file "#{@path}/#{name}.gemspec", :after => /^  s\.license     = "MIT"+\n/ do
  <<-RUBY
  s.metadata    = { 'json' =>
    {
      type: 'widget',
      title: {
        enGb: '#{name.camelcase}',
        deDe: '#{name.camelcase}'
      },
      description: {
        enGb: s.description,
        deDe: 'TODO: Description of #{name.camelcase}'
      },
      groups: [
        # TODO
      ]
    }.to_s
  }
  RUBY
    end
  end

  def app_files
    template "app/assets/templates/settings.vue", "#{@path}/app/assets/templates/settings.vue"
    template "app/assets/templates/display.vue", "#{@path}/app/assets/templates/display.vue"
    template "app/assets/icons/%name%.svg", "#{@path}/app/assets/icons/%name%.svg"
    template "app/models/%name%/%name%_data.rb", "#{@path}/app/models/%name%/%name%_data.rb"
  end

  def lib_files
    template "lib/%name%/fetcher.rb", "#{@path}/lib/%name%/fetcher.rb"
  end

  def append_to_gemfile
    gem name.underscore, path: @path
  end

  def initialize_git_repo
    Dir.chdir(@path)
    git :init
    git add: "."
    git commit: "-m 'initial commit'"
  end

  def show_dev_info
    Thor::Shell::Color.new.say("You can now insert your widget by invoking rails extension:insert[widget, #{name.underscore}]", :yellow)
    Thor::Shell::Color.new.say("To ensure that all files are loaded, please restart the mirros_api Rails app.", :yellow)
  end

end
