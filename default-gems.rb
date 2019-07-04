######
# Rails default Gemfile for API
######
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

source 'https://rubygems.org' do
  gem 'rails', '~> 5.2.3'
  gem 'puma', '~> 3.11'
  gem 'bootsnap', '>= 1.1.0', require: false
  gem 'rack-cors'
  group :development, :test do
    # Call 'byebug' anywhere in the code to stop execution and get a debugger console
    gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  end

  group :development do
    gem 'listen', '>= 3.0.5', '< 3.2'
    # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
    gem 'spring'
    gem 'spring-watcher-listen', '~> 2.0.0'

    gem 'sqlite3', '~> 1.3.6'
    gem 'better_errors', '~> 2.5.0'
    gem 'binding_of_caller', '~> 0.8.0'
    gem 'git', '~> 1.5.0'
    # Data Visualization
    gem 'rails-erd', '~> 1.5.0'
  end

  ### mirr.OS gems ###
  gem 'mysql2', '~> 0.5.2'
  gem 'bundler', '>= 1.17.1' # extension management
  gem 'httparty', '~> 0.16.4' # TODO: Upgrade, but also upgrade extension dependencies
  gem 'jsonapi-resources', '~> 0.9.6'
  gem 'rufus-scheduler', '~> 3.6.0'
  gem 'friendly_id', '~> 5.2.5'
  gem 'os', '~> 1.0.0'
  gem 'terrapin', '~> 0.6.0'
  gem 'ruby-dbus', '~> 0.15.0'
end

### mirr.OS bundled extensions ###
source 'http://gems.marco-roth.ch/' do
  group :widget do
    gem 'clock'
    gem 'countdown'
    gem 'current_date'
    gem 'calendar_event_list'
    gem 'owm_current_weather'
    gem 'owm_forecast'
    gem 'styling'
    gem 'ticker'
    gem 'text_field'
  end

  group :source do
    gem 'openweathermap'
    gem 'ical'
    gem 'rss_feeds'
  end
end

