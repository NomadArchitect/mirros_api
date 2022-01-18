# frozen_string_literal: true

require 'rails/generators/rails/app/app_generator'

class MirrosWidgetGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  argument :name
  argument :fields, optional: true, type: :hash, default: {}

  def initialize_variables
    @fields = fields
    @path = "widgets/#{name}"
    @author_name = `git config --global user.name`.strip
    @author_email = `git config --global user.email`.strip

    o = []
    customizations = {
      'action-mailer': false,
      'active-record': false,
      'active-job': false,
      'active-storage': false,
      controller: false,
      tasks: false,
      test: false
    }
    options.merge(customizations).to_a.each do |name, state|
      o << "--no-skip-#{name}" if state
      o << "--skip-#{name}" unless state
    end

    @pass_options = o.join(' ')
  end

  def generate_plugin
    generate 'plugin', "--mountable #{@path} --api #{@pass_options}"

    # FIXME: Can we disable creation of these via class_option (doesn't seem to work)?
    remove_file "#{@path}/config/routes.rb"
    remove_file "#{@path}/app/controllers"
    remove_file "#{@path}/app/jobs"
    remove_file "#{@path}/app/mailers"
    remove_file "#{@path}/app/models"
    remove_file "#{@path}/lib/#{name}/tasks"
  end

  def app_files
    template 'app/assets/templates/settings.vue', "#{@path}/app/assets/templates/settings.vue"
    template 'app/assets/templates/display.vue', "#{@path}/app/assets/templates/display.vue"
    template 'app/assets/icons/%name%.svg', "#{@path}/app/assets/icons/%name%.svg"
  end

  def config_files
    template Rails.root.join('.rubocop.yml'), "#{@path}/.rubocop.yml"
  end

  def append_to_gemfile
    gem name.underscore, path: @path
  end

  def show_dev_info
    Thor::Shell::Color.new.say("Afterwards, insert your widget by invoking rails extension:insert[#{name.underscore}]", :yellow)
    Thor::Shell::Color.new.say('To ensure that all files are loaded, please restart the mirros_api Rails app.', :red)
  end

  def modify_gemspec
    gemspec = "#{@path}/#{name}.gemspec"
    prepend_to_file gemspec, "require 'json'\n"
    insert_into_file gemspec,
                     after: /^[\s]+spec\.license[\s]+= "MIT"+\n/ do
      <<-RUBY
  spec.metadata    = { 'json' =>
    {
      type: 'widgets',
      title: {
        enGb: '#{name.camelcase}',
        deDe: '#{name.camelcase}'
      },
      description: {
        enGb: spec.description,
        deDe: 'TODO: Description of #{name.camelcase}'
      },
      group: nil, # TODO
      compatibility: '0.0.0',
      sizes: [
        { w: 4, h: 4 }
        # TODO: Default size is 4x4, add additional sizes if your widget supports them.
      ],
      # Add all languages for which your Vue templates are fully translated.
      languages: [:enGb],
      single_source: false # Change to true if your widget doesn't aggregate data from multiple sources.
    }.to_json
  }
      RUBY
    end

    original_version = /spec.add_dependency "rails", "~> [0-9]+.[0-9]+.[0-9]+", ">= [0-9.]*"$/
    gsub_file gemspec, original_version do |_|
      "spec.add_development_dependency 'rails', '#{Gem::Version.new(Rails.version).approximate_recommendation}'"
    end
    gsub_file gemspec, /"TODO(: )?/ do |_|
      '"'
    end
    insert_into_file gemspec, after: /'rails', '~> [0-9]+.[0-9]+'$/ do |_|
      "\nspec.add_development_dependency 'rubocop', '~> 0.81'\nspec.add_development_dependency 'rubocop-rails'\n"
    end
  end
end
