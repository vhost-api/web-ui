# frozen_string_literal: true
source 'https://rubygems.org'

# core
gem 'rack-cache'
gem 'rest-client'
gem 'rest-client-components',
    git: 'https://github.com/amatriain/rest-client-components',
    branch: 'rest-client-2-compatibility'
gem 'sinatra'
gem 'sinatra-contrib'
# tools
gem 'rake', require: false
# engine
gem 'puma'
# style
gem 'filesize'
gem 'haml'
gem 'sass'
gem 'sinatra-flash'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'pry'
  gem 'shotgun', require: false
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
