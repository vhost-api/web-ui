# Installation

1. Clone the git repository to a location of your choice
2. Install gems by running `bundle install --without development test`
3. Copy example config from `config/appconfig.example.yml` to `config/appconfig.yml` and adjust to your preferences
4. Create a session secret for Rack::Session:Cookie by running `bundle exec rake session:invalidate`
5. Run the application: `RACK_ENV="production" bundle exec rackup`
6. Setup Apache or nginx as reverse proxy with SSL and stuff.


## Development setup

+ Remember to access the application using the `localhost.localdomain` URL, otherwise you will have cookie problems
+ Install development and test gems by running `bundle install --with development test`
+ Run the application via `bundle exec shotgun config.ru` to enable auto-reloading of all files at runtime
