source 'https://rubygems.org'

ruby '3.2.0'

# core
gem 'rails', '~> 7.1'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.0'

# auth
gem 'devise', '~> 4.9'
gem 'pundit', '~> 2.3'

# background jobs
gem 'sidekiq', '~> 7.0'
gem 'redis', '~> 5.0'

# api
gem 'jsonapi-serializer'
gem 'rack-cors'

# views
gem 'slim-rails'
gem 'turbo-rails'
gem 'stimulus-rails'

# file uploads
gem 'shrine', '~> 3.5'
gem 'aws-sdk-s3'

# search
gem 'searchkick'
gem 'elasticsearch', '~> 8.0'

# utilities
gem 'tzinfo-data'
gem 'bootsnap', require: false
gem 'nokogiri'

group :development, :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'pry-rails'
end

group :development do
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'brakeman', require: false
  gem 'web-console'
  gem 'bullet'
end

group :test do
  gem 'capybara'
  gem 'webmock'
  gem 'vcr'
end
