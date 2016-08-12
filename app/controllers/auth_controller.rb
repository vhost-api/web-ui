# frozen_string_literal: true
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
  @user = session[:user] unless session[:user].nil?
  authenticate! unless user?
  session[:user] = nil
  flash[:success] = 'Successfully logged out.'
  redirect '/login'
end

get '/login' do
  haml :login, layout: :layout_login
end
