# frozen_string_literal: true

class MirrosSourceGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  argument :name
  argument :fields, optional: true, type: :hash, default: {}


  def initialize_variables
    @fields = fields
    @path = "sources/#{name}"
    @author_name = `git config --global user.name`.strip
    @author_email = `git config --global user.email`.strip

    o = []
    options.to_a.each do |name, state|
      o << "--#{name.dasherize}" if state
      o << "--no-#{name.dasherize}" unless state
    end

    skips = %w[action-mailer active-record active-job active-storage test]
    skips.each do |val|
      o << "--skip-#{val}"
    end

    @pass_options = o.join(' ')
  end

  def generate_plugin
    generate 'plugin', "--mountable #{@path} --api #{@pass_options}"

    # FIXME: Can we disable creation of these via class_option (doesn't seem to work)?
    remove_dir "#{@path}/config"
    remove_dir "#{@path}/app/controllers"
    remove_dir "#{@path}/app/jobs"
    remove_dir "#{@path}/app/mailers"
    remove_dir "#{@path}/lib/#{name}/tasks"

    modify_gemspec
  end

  def app_files
    template 'app/assets/templates/settings.vue', "#{@path}/app/assets/templates/settings.vue"
    template 'app/assets/icons/%name%.svg', "#{@path}/app/assets/icons/%name%.svg"
    template 'app/models/%name%/%name%_data.rb', "#{@path}/app/models/%name%/%name%_data.rb"
  end

  def lib_files
    template 'lib/%name%.rb', "#{@path}/lib/%name%.rb"
    template 'lib/%name%/version.rb', "#{@path}/lib/%name%/version.rb"
    template 'lib/%name%/engine.rb', "#{@path}/lib/%name%/engine.rb"
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
    Thor::Shell::Color.new.say("You can now insert your source by invoking rails extension:insert[source, #{name.underscore}]", :yellow)
    Thor::Shell::Color.new.say('To ensure that all files are loaded, please restart the mirros_api Rails app.', :red)
  end

  def modify_gemspec
    gemspec = "#{@path}/#{name}.gemspec"
    prepend_to_file gemspec, "require 'json'\n"
    insert_into_file gemspec, after: /^[\s]+spec\.license[\s]+= "MIT"+\n/ do
      <<-RUBY
  spec.metadata    = { 'json' =>
    {
      type: 'source',
      title: {
        enGb: '#{name.camelcase}',
        deDe: '#{name.camelcase}'
      },
      description: {
        enGb: spec.description,
        deDe: 'TODO: Description of #{name.camelcase}'
      },
      groups: [], # TODO
      compatibility: '0.0.0'
    }.to_json
  }
      RUBY
    end

    gsub_file gemspec,
              /spec.add_dependency "rails", "~> [0-9]+.[0-9]+.[0-9]+"\n/ do |_|
      "spec.add_development_dependency 'rails', '#{Gem::Version.new(Rails.version).approximate_recommendation}'"
    end
    gsub_file gemspec, /"TODO(: )?/ do |_|
      '"'
    end
  end
end
