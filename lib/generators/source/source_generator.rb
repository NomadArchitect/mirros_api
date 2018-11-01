class SourceGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  argument :name
  argument :fields, optional: true, type: :hash, default: {}
  class_option :mailer, type: :boolean, default: false, desc: "Generate a scoped ActionMailer"
  class_option :job, type: :boolean, default: false, desc: "Generate a scoped ActionJob"
  class_option :controller, type: :boolean, default: false, desc: "Generate a scoped ApplicationController"
  class_option :tasks, type: :boolean, default: false, desc: "Generate a rake tasks file"

  def initialize_variables
    @fields = fields
    @path = "sources/#{self.name}"
    @author_name = `git config --global user.name`.strip
    @author_email = `git config --global user.email`.strip
  end

  def create_directory
    empty_directory @path
  end

  def copy_root_files
   template "Rakefile", "#{@path}/Rakefile"
   template "README.md", "#{@path}/README.md"
   template "MIT-LICENSE", "#{@path}/MIT-LICENSE"
   template "gemspec", "#{@path}/#{name.underscore}.gemspec"
   template "Gemfile", "#{@path}/Gemfile"
  end

  def generate_app_dir
    template "app/assets/templates/settings.vue", "#{@path}/app/assets/templates/settings.vue"
    template "app/assets/icons/name.svg", "#{@path}/app/assets/icons/#{name.underscore}.svg"
    template "app/controllers/name/application_controller.rb", "#{@path}/app/controllers/#{name.underscore}/application_controller.rb" if options[:controller]
    template "app/jobs/name/application_job.rb", "#{@path}/app/jobs/#{name.underscore}/application_job.rb" if options[:job]
    template "app/mailers/name/application_mailer.rb", "#{@path}/app/mailers/#{name.underscore}/application_mailer.rb" if options[:mailer]
    template "app/models/name/application_record.rb", "#{@path}/app/models/#{name.underscore}/application_record.rb"
    # template "app/models/name/name_data.rb", "#{@path}/app/models/#{name.underscore}/#{name.underscore}_data.rb"
  end

  def generate_bin_dir
    template "bin/rails", "#{@path}/bin/rails"
  end

  def generate_config_dir
    template "config/routes.rb", "#{@path}/config/routes.rb"
  end

  def generate_lib_dir
    template "lib/name.rb", "#{@path}/lib/#{name.underscore}.rb"
    template "lib/name/version.rb", "#{@path}/lib/#{name.underscore}/version.rb"
    template "lib/name/engine.rb", "#{@path}/lib/#{name.underscore}/engine.rb"
    template "lib/name/fetcher.rb", "#{@path}/lib/#{name.underscore}/fetcher.rb"
    template "lib/tasks/name_tasks.rake", "#{@path}/lib/tasks/#{name.underscore}_tasks.rake" if options[:tasks]
  end

  def copy_test_dir
    directory "test", "#{@path}/test"
  end

  def append_to_gemfile
    gem name.underscore, path: @path
  end

  def initialize_git_repo
    Dir.chdir(@path)
    git :init
    git add: '.'
    git commit: "-m 'initial commit'"
  end

  def show_dev_info
    Thor::Shell::Color.new.say("You can now insert your widget by invoking rails extension:insert[widget, #{name.underscore}]", :yellow)
  end

end
