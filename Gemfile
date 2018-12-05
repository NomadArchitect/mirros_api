source "https://rubygems.org"
git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end
# Use bundler for extension management
gem "bundler", "~> 1.17.1"
# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "rails", "~> 5.2.0"
# Use postgresql as the database for Active Record
# gem "pg", "~> 1.1.2"
gem 'sqlite3'
# Use Puma as the app server
gem "puma", "~> 3.7"
# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 3.0"
# Use ActiveModel has_secure_password
# gem "bcrypt", "~> 3.1.7"
# Use Capistrano for deployment
# gem "capistrano-rails", group: :development
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem "rack-cors"
# HTTP Client
gem "httparty", "~> 0.16.0"
# CLI
gem "thor", "~> 0.20.0"
gem "highline", "~> 2.0.0"
gem "cli_spinnable", "~> 0.2"
# JSON serialization and parsing
gem "jsonapi-resources", "~> 0.9.0"
# Scheduling and task management
gem "rufus-scheduler", "~> 3.5.2"
# Misc
gem "friendly_id", "~> 5.2.4"
# OS info and commands
gem "os", "~> 1.0.0"
gem "terrapin", "~> 0.6.0"
group :development, :test do
  # Call "byebug" anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
end
group :development do
  gem "listen", ">= 3.0.5", "< 3.2"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
  gem "web-console"
  gem "better_errors", "~> 2.5.0"
  gem "binding_of_caller", "~> 0.8.0"
  gem "git", "~> 1.5.0"
  # Data Visualization
  gem "rails-erd", "~> 1.5.0"
end
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "clock", :group => :widget, :source => "http://gems.marco-roth.ch/"
gem "current_date", :group => :widget, :source => "http://gems.marco-roth.ch/"
gem "calendar_event_list", :group => :widget, :source => "http://gems.marco-roth.ch/"
gem "owm_current_weather", :group => :widget, :source => "http://gems.marco-roth.ch/"
gem "owm_forecast", :group => :widget, :source => "http://gems.marco-roth.ch/"
gem "text_field", :group => :widget, :source => "http://gems.marco-roth.ch/"
gem "styling", :group => :widget, :source => "http://gems.marco-roth.ch/"
gem "openweathermap", :group => :source, :source => "http://gems.marco-roth.ch/"
gem "ical", :group => :source, :source => "http://gems.marco-roth.ch/"
gem "rss_feeds", :group => :source, :source => "http://gems.marco-roth.ch/"
gem "ticker", :group => :widget, :source => "http://gems.marco-roth.ch/"
