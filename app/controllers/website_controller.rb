# frozen_string_literal: true
helpers do
  # @param endpoint [String]
  # @return [Hash, nil]
  def api_query(endpoint)
    apiresponse = RestClient.get(
      api_url(endpoint),
      Authorization: auth_secret_apikey
    )
    parse_apiresponse(apiresponse)
  end

  def auth_secret_apikey
    return nil if @user.nil?
    method = 'VHOSTAPI-KEY'
    credentials = "#{@user[:id]}:#{@user[:api_key]}"
    auth_secret = Base64.encode64(credentials).delete("\n")

    "#{method} #{auth_secret}"
  end

  # @param endpoint [String]
  # @return [String]
  def api_url(endpoint)
    "#{settings.api_url}/api/v#{settings.api_ver}/#{endpoint}"
  end

  # @param apiresponse [RestClientResponse]
  # @return [Hash, nil]
  def parse_apiresponse(apiresponse)
    return nil if apiresponse.code == 404
    JSON.parse(apiresponse.body)
  end
end

post '/login' do
  halt 400, 'invalid request' unless params['user'] && params['password']

  # perform the login request on the api to get an apikey for future requests
  apiresponse = RestClient.post(
    api_url('auth/login'),
    user: params['user'],
    password: params['password'],
    apikey: settings.api_key_id.to_s
  )
  data = parse_apiresponse(apiresponse)

  unless apiresponse.code.eql?(200)
    flash[:error] = 'Invalid Login'
    redirect '/login'
  end

  @user = {
    id: data['user_id'],
    api_key: data['apikey'],
    login: params['user']
  }

  # store stuff for later use
  session[:user] = @user

  flash[:success] = 'Successfully logged in.'

  status 200

  if session[:return_to].nil?
    redirect '/'
  else
    original_request = session[:return_to]
    session[:return_to] = nil
    redirect original_request
  end
end

get '/logout' do
  authenticate!
  session[:user] = nil
  flash[:success] = 'Successfully logged out.'
  redirect '/login'
end

get '/login' do
  haml :login, layout: :layout_login
end

namespace '/user' do
  before do
    @sidebar_title = 'Users'
    @sidebar_elements = ['Users']
  end

  get do
    authenticate!
    @users = api_query('users')
    haml :users
  end
end

namespace '/domains' do
  before do
    @sidebar_title = 'Domains'
    @sidebar_elements = ['Domains']
  end

  get do
    authenticate!
    @domains = api_query('domains')
    haml :domains
  end
end

namespace '/mail' do
  before do
    @sidebar_title = 'Mail'
    @sidebar_elements = %w(Domains Accounts Aliases Sources Forwardings DKIM)
  end

  get do
    authenticate!
    haml :mailhome
  end

  namespace '/domains' do
    get do
      authenticate!
      @domains = api_query('domains')
      haml :domains
    end
  end

  namespace '/accounts' do
    get do
      authenticate!
      @mailaccounts = api_query('mailaccounts')
      haml :mailaccounts
    end

    before %r{\A/(?<id>\d+)/?.*} do
      authenticate!
      @mailaccount = api_query("mailaccounts/#{params[:id]}")
      # 404 = Not Found
      halt 404 if @mailaccount.nil?
    end

    namespace '/:id' do
      get do
        authenticate!
        haml :mailaccount
      end

      get '/edit' do
        authenticate!
        haml :edit_mailaccount
      end
    end
  end

  namespace '/aliases' do
    get do
      authenticate!
      @mailaliases = api_query('mailaliases')
      haml :mailaliases
    end
  end

  namespace '/sources' do
    get do
      authenticate!
      @mailaliases = api_query('mailsources')
      haml :mailsources
    end
  end

  namespace '/dkim' do
    get do
      authenticate!
      @dkims = api_query('dkims')
      @dkimsignings = api_query('dkimsignings')
      haml :dkim
    end
  end
end

namespace '/webhosting' do
  before do
    @sidebar_title = 'Webhosting'
    @sidebar_elements = %w(VHosts SFTPUsers ShellUsers)
  end

  get do
    authenticate!
    @phpruntimes = api_query('phpruntimes')
    @ipv4addresses = api_query('ipv4addresses')
    @ipv6addresses = api_query('ipv6addresses')
    haml :webhostinghome
  end

  namespace '/vhosts' do
    get do
      authenticate!
      @vhosts = api_query('vhosts')
      haml :vhosts
    end
  end

  namespace '/sftpusers' do
    get do
      authenticate!
      @sftpusers = api_query('sftpusers')
      haml :sftpusers
    end
  end

  namespace '/shellusers' do
    get do
      authenticate!
      @shellusers = api_query('shellusers')
      haml :shellusers
    end
  end
end

namespace '/dns' do
  before do
    @sidebar_title = 'DNS'
    @sidebar_elements = %w(Domains Zones Templates)
  end

  get do
    authenticate!
    haml :dnshome
  end

  namespace '/domains' do
    get do
      authenticate!
      @domains = api_query('domains')
      haml :domains
    end
  end
end
