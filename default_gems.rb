# frozen_string_literal: true

ruby '2.6.6'

######
# Rails default Gemfile for API
######
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

source 'https://rubygems.org' do
  gem 'rails', '~> 5.2.3'
  gem 'puma', '~> 4.0.1'
  gem 'bootsnap', '>= 1.1.0', require: false
  gem 'rack-cors'
  group :development, :test do
    # Call 'byebug' anywhere in the code to stop execution and get a debugger console
    gem 'byebug', platforms: %i[mri mingw x64_mingw]
  end

  group :development do
    gem 'listen', '>= 3.0.5', '< 3.2'
    # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
    gem 'spring'
    gem 'spring-watcher-listen', '~> 2.0.0'
    gem 'better_errors', '~> 2.5.0'
    gem 'binding_of_caller', '~> 0.8.0'
    gem 'git', '~> 1.5.0'
    # Data Visualization
    gem 'rails-erd', '~> 1.6.0'
    gem 'rubocop'
    gem 'rubocop-rails'
  end

  ### mirr.OS gems ###
  gem 'mysql2', '~> 0.5.2'
  gem 'bundler', '>= 1.17.1' # extension management
  gem 'httparty', '~> 0.18'
  gem 'jsonapi-resources', '~> 0.9.10'
  gem 'rufus-scheduler', '~> 3.6.0'
  gem 'friendly_id', '~> 5.2.5'
  gem 'os', '~> 1.0.0'
  gem 'terrapin', '~> 0.6.0'
  gem 'ruby-dbus', '~> 0.16.0'
  gem 'image_processing', '~> 1.9'
end

### mirr.OS bundled extensions ###
source 'https://extensions.glancr.net/' do
  group :widget do
    gem 'bing_traffic'
    gem 'calendar_event_list'
    gem 'calendar_week_overview'
    gem 'calendar_upcoming_event'
    gem 'clock'
    gem 'countdown'
    gem 'current_date'
    gem 'fuel_prices'
    gem 'idioms'
    gem 'ip_cam'
    gem 'network'
    gem 'owm_current_weather'
    gem 'owm_daily_values'
    gem 'owm_forecast'
    gem 'pictures'
    gem 'public_transport_departures'
    gem 'styling'
    gem 'text_field'
    gem 'ticker'
    gem 'todos'
    gem 'qrcode'
    gem 'video_player'
  end

  group :source do
    gem 'ical'
    gem 'openweathermap'
    gem 'rss_feeds'
    gem 'idioms_source'
    # gem 'urban_dictionary'
    gem 'sbb'
    gem 'todoist'
    gem 'vbb'
    gem 'mirros-source-netatmo'
  end
end
