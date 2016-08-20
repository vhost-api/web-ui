# frozen_string_literal: true
post '/login' do
  unless params['user'] && params['password']
    flash[:error] = 'Missing parameters'
    redirect '/login'
  end

  # perform the login request on the api to get an apikey for future requests
  begin
    apiresponse = RestClient.post(
      gen_api_url('auth/login'),
      user: params['user'],
      password: params['password'],
      apikey_comment: settings.api_key_comment.to_s
    )
    data = parse_apiresponse(apiresponse)
  rescue => err
    data = parse_apiresponse(err.response)
    data[:code] = err.response.code
  end

  if data.key?(:code)
    msg = 'Invalid Login'
    if settings.environment == :development
      msg += "</br>#{data['status']}: #{data['error_id']}, #{data['message']}"
    end
    flash[:error] = msg
    redirect '/login'
  end

  @user = {
    id: data['user_id'],
    api_key: data['apikey'],
    login: params['user']
  }

  # store stuff for later use
  session[:user] = @user

  # fetch enabled modules
  _dummy, modules = api_query("users/#{@user[:id]}/enabled_modules")
  session[:modules] = modules

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
  @user = session[:user] unless session[:user].nil?
  authenticate! unless user?
  session[:user] = nil
  flash[:success] = 'Successfully logged out.'
  redirect '/login'
end

get '/login' do
  haml :login, layout: :layout_login
end
