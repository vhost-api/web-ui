# frozen_string_literal: true
namespace '/packages' do
  before do
    @sidebar_title = 'Packages'
    @sidebar_elements = []
  end

  get do
    ui_output('packages')
  end

  get '/new' do
    @users = { '0' => { 'id' => 0, 'name' => 'Please select a user...' } }
    _dummy, existing_users = api_query('users')
    @users.merge!(existing_users)
    ui_create('Package', user_opts: 'user_select_options_package')
  end

  post do
    create_params = {}
    create_params[:user_id] = params['user_id'].to_i
    create_params[:name] = params['name']
    create_params[:price_unit] = params['price_unit']
    create_params[:enabled] = if params['enabled'].nil?
                                false
                              else
                                string_to_bool(params['enabled'])
                              end

    # quota stuff
    params.each_key do |k|
      create_params[k.to_sym] = params[k] if k =~ %r{^quota}
    end

    result = api_create('packages', create_params)

    flash_status = 'error'
    if result['status'] == 'success'
      @record = result['data']['object']
      msg = "Successfully created Package #{@record['id']}, #{@record['name']}"
      flash_status = 'success'
    else
      err_id, msg, errors = parse_api_error(result)
    end

    if params['ajax'].nil?
      flash[flash_status.to_sym] = msg
      redirect '/packages'
    else
      reply = { status: flash_status, msg: msg, redirect: '/packages' }
      reply['error_id'] = err_id if errors
      reply['errors'] = errors if errors
      halt 200, reply.to_json
    end
  end

  namespace'/:id' do
    get '/edit' do
      _dummy, @record = api_query("packages/#{params['id']}")
      check_response(@record)
      _dummy, @users = api_query('users')
      ui_edit('Package', user_opts: 'user_select_options_package')
    end

    post do
      update_params = {}
      user_id = params['user_id'].to_i
      update_params[:user_id] = user_id unless user_id.zero?
      update_params[:name] = params['name']
      update_params[:price_unit] = params['price_unit']
      update_params[:enabled] = if params['enabled'].nil?
                                  false
                                else
                                  string_to_bool(params['enabled'])
                                end

      # quota stuff
      params.each_key do |k|
        update_params[k.to_sym] = params[k] if k =~ %r{^quota}
      end

      result = api_update("packages/#{params['id']}", update_params)

      flash_status = 'error'
      if result['status'] == 'success'
        @record = result['data']['object']
        msg = "Successfully updated Package #{@record['id']}, #{@record['name']}"
        flash_status = 'success'
      else
        err_id, msg, errors = parse_api_error(result)
      end

      if params['ajax'].nil?
        flash[flash_status.to_sym] = msg
        redirect '/packages'
      else
        reply = { status: flash_status, msg: msg, redirect: '/packages' }
        reply['error_id'] = err_id if errors
        reply['errors'] = errors if errors
        halt 200, reply.to_json
      end
    end

    get '/delete' do
      _dummy, record = api_query("packages/#{params['id']}")
      @delete = {
        class_name: 'Package',
        name: 'delete_package',
        endpoint: 'packages',
        id: record['id'],
        detail: record['name']
      }
      ui_delete(ajax: params['ajax'].nil? ? false : true)
    end

    post '/delete' do
      resource = "packages/#{params['id']}"
      _dummy, record = api_query(resource)
      result = api_delete(resource)

      flash_status = 'error'
      if result['status'] == 'success'
        msg = "Successfully deleted Package #{record['id']} (#{record['name']})"
        flash_status = 'success'
      else
        _err_id, msg = parse_api_error(result)
      end

      if params['ajax'].nil?
        flash[flash_status.to_sym] = msg
        redirect '/packages'
      else
        halt 200, { status: flash_status, msg: msg }.to_json
      end
    end
  end
end
