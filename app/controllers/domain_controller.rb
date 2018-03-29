# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace '/domains' do
  before do
    @sidebar_title = 'Domains'
    @sidebar_elements = []
  end

  get do
    ui_output(
      'domains',
      fields: %w[id name mail_enabled dns_enabled created_at updated_at enabled
                 user].join(',')
    )
  end

  get '/new' do
    @users = { '0' => { 'id' => 0, 'name' => 'Please select a user...' } }
    _dummy, existing_users = api_query('users')
    @users.merge!(existing_users)
    ui_create('Domain', user_opts: 'user_select_options')
  end

  post do
    create_params = {}
    create_params[:user_id] = params['user_id'].to_i
    create_params[:name] = params['name']
    %w[mail_enabled dns_enabled enabled].each do |k|
      create_params[k.to_sym] = if params[k].nil?
                                  false
                                else
                                  string_to_bool(params[k])
                                end
    end

    result = api_create('domains', create_params)

    flash_status = 'error'
    if result['status'] == 'success'
      @record = result['data']['object']
      msg = "Successfully created Domain #{@record['id']}, #{@record['name']}"
      flash_status = 'success'
    else
      err_id, msg, errors = parse_api_error(result)
    end

    if params['ajax'].nil?
      flash[flash_status.to_sym] = msg
      redirect '/domains'
    else
      reply = { status: flash_status, msg: msg, redirect: '/domains' }
      reply['error_id'] = err_id if errors
      reply['errors'] = errors if errors
      halt 200, reply.to_json
    end
  end

  namespace '/:id' do
    get '/edit' do
      _dummy, @record = api_query("domains/#{params['id']}")
      check_response(@record)
      _dummy, @users = api_query('users')
      ui_edit('Domain', user_opts: 'user_select_options')
    end

    post do
      update_params = {}
      update_params[:user_id] = params['user_id'].to_i
      update_params[:name] = params['name']
      %w[mail_enabled dns_enabled enabled].each do |k|
        update_params[k.to_sym] = if params[k].nil?
                                    false
                                  else
                                    string_to_bool(params[k])
                                  end
      end

      result = api_update("domains/#{params['id']}", update_params)

      flash_status = 'error'
      if result['status'] == 'success'
        @record = result['data']['object']
        msg = "Successfully updated Domain #{@record['id']}, #{@record['name']}"
        flash_status = 'success'
      else
        err_id, msg, errors = parse_api_error(result)
      end

      if params['ajax'].nil?
        flash[flash_status.to_sym] = msg
        redirect '/domains'
      else
        reply = { status: flash_status, msg: msg, redirect: '/domains' }
        reply['error_id'] = err_id if errors
        reply['errors'] = errors if errors
        halt 200, reply.to_json
      end
    end

    get '/delete' do
      _dummy, record = api_query("domains/#{params['id']}")
      @delete = {
        class_name: 'Domain',
        name: 'delete_domain',
        endpoint: 'domains',
        id: record['id'],
        detail: record['name']
      }
      ui_delete(ajax: params['ajax'].nil? ? false : true)
    end

    post '/delete' do
      resource = "domains/#{params['id']}"
      _dummy, record = api_query(resource)
      result = api_delete(resource)

      flash_status = 'error'
      if result['status'] == 'success'
        msg = "Successfully deleted Domain #{record['id']} (#{record['name']})"
        flash_status = 'success'
      else
        _err_id, msg = parse_api_error(result)
      end

      if params['ajax'].nil?
        flash[flash_status.to_sym] = msg
        redirect '/domains'
      else
        halt 200, { status: flash_status, msg: msg }.to_json
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
