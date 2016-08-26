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
    ui_create('Package', user_opts: 'user_select_options')
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

    if result['status'] == 'success'
      @record = result['data']['object']
      msg = "Successfully created Package #{@record['id']}, #{@record['name']}"
      flash[:success] = msg
      redirect '/packages'
    else
      err_id, msg = parse_api_error(result)
      flash[:error] = msg
      case err_id
      when '1003' then
        # not found
        redirect '/packages'
      when '1002' then
        # permission denied or quota exhausted
        redirect '/packages'
      else
        # try again
        redirect '/packages/new'
      end
    end
  end

  namespace'/:id' do
    get '/edit' do
      _dummy, @record = api_query("packages/#{params['id']}")
      _dummy, @users = api_query('users')
      ui_edit('Package', user_opts: 'user_select_options')
    end

    post do
      update_params = {}
      update_params[:user_id] = params['user_id'].to_i
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

      if result['status'] == 'success'
        msg = "Successfully updated Package #{params['id']}, #{params['name']}"
        flash[:success] = msg
        @record = result['data']['object']
        redirect '/packages'
      else
        err_id, msg = parse_api_error(result)
        flash[:error] = msg
        case err_id
        when '1003' then
          # not found
          redirect '/packages'
        when '1002' then
          # permission denied or quota exhausted
          redirect '/packages'
        else
          # try again
          redirect "/packages/#{params['id']}/edit"
        end
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
      ui_delete
    end

    post '/delete' do
      resource = "packages/#{params['id']}"
      _dummy, record = api_query(resource)
      result = api_delete(resource)

      if result['status'] == 'success'
        msg = "Successfully deleted Package #{record['id']} (#{record['name']})"
        flash[:success] = msg
      else
        s = result['status']
        e = result['error_id']
        m = result['message']
        msg = "#{s}: #{e}, #{m}"
        flash[:error] = msg
      end
      redirect '/packages'
    end
  end
end
