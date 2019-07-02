######
# Rails default Gemfile for API
######

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.3'
# Use sqlite3 as the database for Active Record
# gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.11'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use ActiveStorage variant
# gem 'mini_magick', '~> 4.8'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.1.0', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
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
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

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

group :development do
  gem 'sqlite3', '~> 1.3.6'
  gem 'better_errors', '~> 2.5.0'
  gem 'binding_of_caller', '~> 0.8.0'
  gem 'git', '~> 1.5.0'
  # Data Visualization
  gem 'rails-erd', '~> 1.5.0'
end

### mirr.OS bundled extensions ###
source 'http://gems.marco-roth.ch/'

group :widget do
  gem 'clock'
  gem 'countdown'
  gem 'current_date'
  gem 'calendar_event_list'
  gem 'owm_current_weather'
  gem 'owm_forecast'
  gem 'text_field'
  gem 'ticker'
end

group :source do
  gem 'openweathermap'
  gem 'ical'
  gem 'rss_feeds'
end
