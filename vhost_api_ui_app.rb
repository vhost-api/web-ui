# frozen_string_literal: true

require 'bundler/setup'

require 'rest-client'
require 'restclient/components'
require 'rack/cache'
require 'sinatra'
require 'sinatra/contrib'
require 'sinatra/flash'
require 'tilt/haml'
require 'json'
require 'base64'
require 'securerandom'
require 'digest/sha1'
require 'sass'
require 'filesize'

Dir.glob('./app/classes/*.rb').each { |file| require file }
Dir.glob('./app/helpers/*.rb').each { |file| require file }

configure do
  set :root, File.expand_path('app/', __dir__)
  set :views, File.expand_path('app/views', __dir__)
  set :jsdir, 'js'
  set :cssdir, 'css'
  enable :coffeescript
  set :cssengine, 'scss'
  set :start_time, Time.now
  set :logging, false
  # rubocop:disable Security/YAMLLoad
  @appconfig = YAML.load(
    File.read('config/appconfig.yml')
  )[settings.environment.to_s]
  # rubocop:enable Security/YAMLLoad
  @appconfig.keys.each do |key|
    set key, @appconfig[key]
  end
  use Rack::Deflater
  RestClient.enable Rack::Cache,
                    metastore: 'file:./tmp/cache/meta',
                    entitystore: 'file:./tmp/cache/body'
  include GenericHelpers
  include APIHelpers
  include UIHelpers
  include FormHelpers
end

configure :development, :test do
  require 'pry'
  require 'better_errors'
  require 'binding_of_caller'
  set :show_exceptions, :after_handler
  set :raise_errors, false
  use BetterErrors::Middleware
  BetterErrors.application_root = settings.root
  BetterErrors.use_pry!
  RestClient.enable Rack::CommonLogger
  use Rack::Session::Cookie, secret: File.read('config/session.secret'),
                             key: settings.session[:key].to_s,
                             domain: settings.session[:domain].to_s,
                             expire_after: settings.session[:timeout],
                             path: settings.session[:path].to_s
end

configure :production do
  set :show_exceptions, false
  set :raise_errors, false
  use Rack::Session::Cookie, secret: File.read('config/session.secret'),
                             key: settings.session[:key].to_s,
                             domain: settings.session[:domain].to_s,
                             expire_after: settings.session[:timeout],
                             path: settings.session[:path].to_s,
                             secure: true
end

before do
  @user = session[:user] unless session[:user].nil?
  authenticate! unless request.path_info =~ %r{/(login|css|img)}
  set_title
  set_sidebar_title
end

Dir.glob('./app/controllers/*.rb').each { |file| require file }

get '/js/*.js' do
  pass unless settings.coffeescript?
  last_modified File.mtime(settings.root + '/views/' + settings.jsdir)
  content_type :js
  cache_control :public, :must_revalidate
  coffee [settings.jsdir, params[:splat].first].join('/').to_sym
end

get '/css/*.css' do
  last_modified File.mtime(settings.root + '/views/' + settings.cssdir)
  content_type :css
  cache_control :public, :must_revalidate
  send(settings.cssengine,
       [settings.cssdir, params[:splat].first].join('/').to_sym)
end

get '/' do
  response_digest, @result = api_query("users/#{@user[:id]}/quota_stats", {})
  etag response_digest if session[:flash].nil? || session[:flash].empty?
  haml :home, layout: :layout
end

get '/session' do
  session.to_hash.to_json
end

get '/stats' do
  haml :stats
end

get '/settings' do
  haml :settings
end

not_found do
  haml :not_found
end

error Errno::ENETUNREACH do
  haml :api_unavailable
end
