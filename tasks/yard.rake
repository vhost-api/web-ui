# frozen_string_literal: true
begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
    t.files = ['./app/controllers/**/*.rb',
               './app/helpers/**/*.rb',
               './app/models/**/*.rb']
  end

rescue LoadError
  task :yard do
    abort 'YARD is not available. In order to run yard, you must install yard'
  end
end
