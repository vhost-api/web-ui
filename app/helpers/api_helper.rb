# frozen_string_literal: true
# @param endpoint [String]
# @return [Hash, nil]
def api_query(endpoint)
  apiresponse = RestClient.get(
    gen_api_url(endpoint),
    Authorization: auth_secret_apikey
  )
  [apiresponse.headers[:etag], parse_apiresponse(apiresponse)]
rescue RestClient::ExceptionWithResponse => err
  [nil, parse_apiresponse(err.response)]
end

# @param resource [String]
# @param params [Hash]
# @return [Hash, nil]
def api_update(resource, params)
  apiresponse = RestClient::Request.execute(
    method: :patch,
    url: gen_api_url(resource),
    headers: { Authorization: auth_secret_apikey },
    payload: params.to_json
  )
  parse_apiresponse(apiresponse)
rescue RestClient::ExceptionWithResponse => err
  parse_apiresponse(err.response)
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
def gen_api_url(endpoint)
  "#{settings.api_url}/api/v#{settings.api_ver}/#{endpoint}"
end

# @param apiresponse [RestClientResponse]
# @return [Hash]
def parse_apiresponse(apiresponse)
  JSON.parse(apiresponse.body)
end