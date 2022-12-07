# frozen_string_literal: true

ruby '2.6.9'

######
# Rails default Gemfile for API
######

source 'https://rubygems.org' do
  gem 'rails', '~> 5.2.3'
  gem 'puma', '~> 4.0.1'
  gem 'bootsnap', '>= 1.1.0', require: false
  gem 'rack-cors'

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
  gem 'redis'
  gem 'dotenv-rails'
  gem 'mysql2', '~> 0.5.2'
  gem 'httparty', '~> 0.18'
  gem 'jsonapi-resources', '~> 0.9.10'
  gem 'friendly_id', '~> 5.2.5'
  gem "lhc", "~> 13.2"
  gem 'os', '~> 1.0.0'
  gem 'terrapin', '~> 0.6.0'
  gem 'ruby-dbus', '~> 0.16.0'
  gem 'image_processing', '~> 1.9'
  gem 'store_model', '~> 0.8'
  gem 'sidekiq', '< 7'
  gem 'sidekiq-scheduler', '~> 3.1'
end

### mirr.OS bundled extensions ###
group :widget do
  gem 'bing_traffic', path: 'widgets/bing_traffic'
  gem 'calendar_event_list', path: 'widgets/calendar_event_list'
  gem 'calendar_week_overview', path: 'widgets/calendar_week_overview'
  gem 'calendar_upcoming_event', path: 'widgets/calendar_upcoming_event'
  gem 'clock', path: 'widgets/clock'
  gem 'countdown', path: 'widgets/countdown'
  gem 'current_date', path: 'widgets/current_date'
  gem 'mirros-widget-embed_pdf', path: 'widgets/mirros-widget-embed_pdf'
  gem 'fuel_prices', path: 'widgets/fuel_prices'
  gem 'idioms', path: 'widgets/idioms'
  gem 'ip_cam', path: 'widgets/ip_cam'
  gem 'mirros-widget-embed_iframe', path: 'widgets/mirros-widget-embed_iframe'
  gem 'network', path: 'widgets/network'
  gem 'owm_current_weather', path: 'widgets/owm_current_weather'
  gem 'owm_daily_values', path: 'widgets/owm_daily_values'
  gem 'owm_forecast', path: 'widgets/owm_forecast'
  gem 'pictures', path: 'widgets/pictures'
  gem 'public_transport_departures', path: 'widgets/public_transport_departures'
  gem 'styling', path: 'widgets/styling'
  gem 'text_field', path: 'widgets/text_field'
  gem 'ticker', path: 'widgets/ticker'
  gem 'todos', path: 'widgets/todos'
  gem 'qrcode', path: 'widgets/qrcode'
  gem 'video_player', path: 'widgets/video_player'
end

group :source do
  gem 'ical', path: 'sources/ical'
  gem 'openweathermap', path: 'sources/openweathermap'
  gem 'rss_feeds', path: 'sources/rss_feeds'
  gem 'idioms_source', path: 'sources/idioms_source'
  gem 'sbb', path: 'sources/sbb'
  gem 'todoist', path: 'sources/todoist'
  gem 'vbb', path: 'sources/vbb'
  gem 'mirros-source-netatmo', path: 'sources/mirros-source-netatmo'
  gem 'mirros-source-microsoft_todo', path: 'sources/mirros-source-microsoft_todo'
end
