# frozen_string_literal: true
source 'https://rubygems.org'

# core
gem 'rest-client'
gem 'rest-client-components',
    git: 'https://github.com/amatriain/rest-client-components',
    branch: 'rest-client-2-compatibility'
gem 'rack-cache'
gem 'rack-ssl'
gem 'sinatra'
gem 'sinatra-contrib'
# tools
gem 'rake', require: false
# engine
gem 'puma'
# style
gem 'sinatra-flash'
gem 'haml'
gem 'sass'
gem 'filesize'

group :development do
  gem 'shotgun', require: false
  gem 'pry'
  gem 'better_errors'
  gem 'binding_of_caller'
end

group :test, :development do
  # gem 'yard', require: false
  # gem 'simplecov', require: false
  # gem 'rspec', require: false
  gem 'rubocop', require: false
  # gem 'rubocop-rspec', require: false
  gem 'astrolabe', require: false
  gem 'haml-lint', require: false
  # gem 'faker', require: false
end
