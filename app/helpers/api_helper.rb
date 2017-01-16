# frozen_string_literal: true
# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
# collection of helpers for communication with the API
module APIHelpers
  # @param etag [String]
  # @param response [Hash]
  # @return [Array((nil, String), Hash)]
  def extract_api_data(etag = '', apiresponse = {})
    parsed_response = parse_apiresponse(apiresponse)
    return [nil, { error: 'invalid response' }] if parsed_response['data'].nil?
    if parsed_response['data'].key?('object')
      [etag, parsed_response['data']['object']]
    elsif parsed_response['data'].key?('objects')
      [etag, parsed_response['data']['objects']]
    else
      # just passthrough
      [etag, parsed_response]
    end
  end

  # @param endpoint [String]
  # @return [Hash, nil]
  def api_query(endpoint, params = {})
    apiresponse = RestClient.get(
      gen_api_url(endpoint),
      params: params,
      Authorization: auth_secret_apikey,
      content_type: :json
    )
    extract_api_data(apiresponse.headers[:etag], apiresponse)
  rescue RestClient::ExceptionWithResponse => err
    c = err.response.code
    session_expired if c.eql?(401)
    api_unreachable if c.eql?(502)

    parsed_data = parse_apiresponse(err.response)
    parsed_data[:code] = c
    [nil, parsed_data]
  end

  # @param resource [String]
  # @param params [Hash]
  # @return [Hash, nil]
  def api_update(resource, params)
    apiresponse = RestClient::Request.execute(
      method: :patch,
      url: gen_api_url(resource) + '?verbose',
      headers: {
        Authorization: auth_secret_apikey,
        content_type: :json
      },
      payload: params.to_json
    )
    parse_apiresponse(apiresponse)
  rescue RestClient::ExceptionWithResponse => err
    parse_apiresponse(err.response)
  end

  # @param resource [String]
  # @return [Hash, nil]
  def api_delete(resource)
    apiresponse = RestClient::Request.execute(
      method: :delete,
      url: gen_api_url(resource) + '?verbose',
      headers: {
        Authorization: auth_secret_apikey,
        content_type: :json
      }
    )
    parse_apiresponse(apiresponse)
  rescue RestClient::ExceptionWithResponse => err
    parse_apiresponse(err.response)
  end

  # @param resource [String]
  # @param params [Hash]
  # @return [Hash, nil]
  def api_create(resource, params)
    apiresponse = RestClient::Request.execute(
      method: :post,
      url: gen_api_url(resource) + '?verbose',
      headers: {
        Authorization: auth_secret_apikey,
        content_type: :json
      },
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

  # @return [String]
  def parse_api_error(result)
    e = result['error_id']
    msg = "#{result['status']}: #{e}, #{result['message']}"
    errors = {}
    unless result['data'].nil?
      errors = result.fetch('data', {}).fetch('errors', {}) || {}
    end
    [e, msg, errors]
  end

  # @param endpoint [String]
  # @return [String]
  def gen_api_url(endpoint)
    "#{settings.api_url}/api/v#{settings.api_ver}/#{endpoint}"
  end

  # @param apiresponse [RestClientResponse]
  # @return [Hash]
  def parse_apiresponse(apiresponse)
    begin
      JSON.parse(apiresponse.body)
    rescue JSON::ParserError => err
      p(err)
      # p(err.backtrace)
      p('invalid json: ' + apiresponse.body)
      halt 400, { status: 'error', msg: 'invalid request (invalid json)', errors: [err] }.to_json
    end
  end

  # @param response [Hash]
  # @return [Boolean]
  def check_response(response)
    halt 500, haml(:internal_error) if response.nil?
    if response.key?('status')
      return true if response['status'] == 'success'
      err_id, @msg = parse_api_error(response)
      case err_id
      when '1004' then
        halt 404, haml(:not_found)
      when '1003' then
        halt 403, haml(:unauthorized)
      else
        @result = response
        halt 400, haml(:api_error)
      end
    end
    true
  end
end
