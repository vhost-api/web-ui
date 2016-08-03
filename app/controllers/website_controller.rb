# frozen_string_literal: true
helpers do
  # @param endpoint [String]
  # @return [Hash, nil]
  def api_query(endpoint)
    halt 401, 'invalid cookie' if @cookie.nil?
    apiresponse = RestClient.get(
      api_url(endpoint),
      cookies: { settings.session_key => @cookie }
    )
    response_cookie(apiresponse.cookies[settings.session_key])
    parse_apiresponse(apiresponse)
  end

  # @param endpoint [String]
  # @return [String]
  def api_url(endpoint)
    "#{settings.api_url}/api/v#{settings.api_ver}/#{endpoint}"
  end

  # @param cookie [String]
  def response_cookie(cookie)
    response.set_cookie(
      settings.session_key,
      value: cookie
    )
  end

  # @param apiresponse [RestClientResponse]
  # @return [Hash, nil]
  def parse_apiresponse(apiresponse)
    return nil if apiresponse.code == 404
    JSON.parse(apiresponse.body)
  end
end

get '/login' do
  haml :login, layout: :layout_login
end

post '/login' do
  apiresponse = RestClient::Request.execute(
    method: :post,
    url: "#{settings.api_url}/api/v#{settings.api_ver}/auth/login",
    payload: { user: { login: params['user'], password: params['password'] } },
    max_redirects: 0
  )
  if apiresponse.code == 200
    status 302
    response.set_cookie(
      settings.session_key,
      value: apiresponse.cookies[settings.session_key]
    )
    redirect '/'
  else
    redirect '/login'
  end
end

get '/logout' do
  apiresponse = RestClient.get(
    "#{settings.api_url}/api/v#{settings.api_ver}/auth/logout",
    cookies: {
      settings.session_key => @cookies[settings.session_key]
    }
  )
  [apiresponse.code, apiresponse.headers, apiresponse.body]
end

namespace '/user' do
  before do
    @sidebar_title = 'Users'
    @sidebar_elements = ['Users']
  end

  get do
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
    haml :mailhome
  end

  namespace '/domains' do
    get do
      @domains = api_query('domains')
      haml :domains
    end
  end

  namespace '/accounts' do
    get do
      @mailaccounts = api_query('mailaccounts')
      haml :mailaccounts
    end

    before %r{\A/(?<id>\d+)/?.*} do
      @cookie = request.cookies[settings.session_key]
      @mailaccount = api_query("mailaccounts/#{params[:id]}")
      p @mailaccount
      # 404 = Not Found
      halt 404 if @mailaccount.nil?
    end

    namespace '/:id' do
      get do
        haml :mailaccount
      end

      get '/edit' do
        haml :edit_mailaccount
      end
    end
  end

  namespace '/aliases' do
    get do
      @mailaliases = api_query('mailaliases')
      haml :mailaliases
    end
  end

  namespace '/sources' do
    get do
      @mailaliases = api_query('mailsources')
      haml :mailsources
    end
  end

  namespace '/dkim' do
    get do
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
    @phpruntimes = api_query('phpruntimes')
    @ipv4addresses = api_query('ipv4addresses')
    @ipv6addresses = api_query('ipv6addresses')
    haml :webhostinghome
  end

  namespace '/vhosts' do
    get do
      @vhosts = api_query('vhosts')
      haml :vhosts
    end
  end

  namespace '/sftpusers' do
    get do
      @sftpusers = api_query('sftpusers')
      haml :sftpusers
    end
  end

  namespace '/shellusers' do
    get do
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
    haml :dnshome
  end

  namespace '/domains' do
    get do
      @domains = api_query('domains')
      haml :domains
    end
  end
end
