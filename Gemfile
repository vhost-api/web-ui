# frozen_string_literal: true

source 'https://rubygems.org'

# core
gem 'rack-cache', '~> 1.7', '>= 1.7.1'
gem 'rest-client', '~> 2.0', '>= 2.0.2'
gem 'rest-client-components', '~> 1.5'
gem 'sinatra', '~> 2.0', '>= 2.0.1'
gem 'sinatra-contrib', '~> 2.0', '>= 2.0.1'
# tools
gem 'rake', '~> 12.0', require: false
# engine
gem 'puma', '~> 4.3', '>= 4.3.12'
# style
gem 'filesize', '~> 0.1', '>= 0.1.1'
gem 'haml', '~> 5.0', '>= 5.0.4'
gem 'sass', '~> 3.5', '>= 3.5.6'
gem 'sinatra-flash', '~> 0.3'
gem 'tilt', '~> 2.0', '>= 2.0.8'

group :development do
  gem 'better_errors', '~> 2.4'
  gem 'pry', '~> 0.11', '>= 0.11.3'
  gem 'shotgun', '~> 0.9', '>= 0.9.2', require: false
end

group :test, :development do
  gem 'astrolabe', '~> 1.3', '>= 1.3.1', require: false
  gem 'haml-lint', '~> 0.999', '>= 0.999.999', require: false
  gem 'rubocop', '~> 0.54', require: false
  gem 'rubocop-rspec', '~> 1.24', require: false
end
