source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "rails", "~> 5.1.5"

# Use postgresql as the database for Active Record
gem "pg", "~> 0.18"

# Use Puma as the app server
gem "puma", "~> 3.7"

# Use Redis adapter to run Action Cable in production
# gem "redis", "~> 3.0"

# Use ActiveModel has_secure_password
# gem "bcrypt", "~> 3.1.7"

# Use Capistrano for deployment
# gem "capistrano-rails", group: :development

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
# gem "rack-cors"

# JavaScript / CSS
gem "turbolinks", "~> 5.1.0"
gem "jquery-rails", "~> 4.3.0"
gem "sass-rails", "~> 5.0.0"
gem "webpacker", "~> 3.3.0"

# Form Builder
gem "simple_form", "~> 3.5.0"

# Data Visualization
gem "rails-erd", "~> 1.5.0"

# HTTP Client
gem "httparty", "~> 0.16.0"

# CLI
gem "thor", "~> 0.20.0"
gem "highline", "~> 1.7.10"
gem "cli_spinnable", "~> 0.2"

# JSON serialization and parsing
gem "jsonapi-resources", "~> 0.9.0"
gem "jbuilder", "~> 2.5"
gem "json-schema", "~> 2.8.0"
# gem "active_model_serializers", "~> 0.10.6"

# Misc
gem "git", "~> 1.3.0"
gem "rubyzip", "~> 1.2.0"
gem "friendly_id", "~> 5.1.0"

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
  gem "better_errors", "~> 2.4.0"
  gem "binding_of_caller", "~> 0.8.0"
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
# gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
