# frozen_string_literal: true
namespace '/users' do
  before do
    @sidebar_title = 'Users'
    @sidebar_elements = []
  end

  get do
    ui_output(
      'users',
      fields: %w(id name login contact_email created_at updated_at reseller
                 group enabled).join(',')
    )
  end

  get '/new' do
    # prefetch groups
    @groups = { '0' => { 'id' => 0, 'name' => 'Please select a group...' } }
    _dummy, existing_groups = api_query('groups')
    @groups.merge!(existing_groups)

    # prefetch packages
    _dummy, @packages = api_query('packages')

    ui_create('User',
              group_opts: 'group_select_options',
              package_opts: 'package_select_options')
  end

  post do
    create_params = {}

    # passwords must match
    passwd = params['password']
    unless passwd == params['password2']
      flash[:error] = 'Passwords must match'
      redirect '/users/new'
    end
    create_params[:password] = passwd unless passwd.nil? || passwd == ''
    p(passwd)
    p(create_params[:password])

    create_params[:group_id] = params['group_id'].to_i
    create_params[:name] = params['name']
    create_params[:login] = params['login']
    create_params[:contact_email] = params['contact_email']
    create_params[:enabled] = if params['enabled'].nil?
                                false
                              else
                                string_to_bool(params['enabled'])
                              end

    result = api_create('users', create_params)

    if result['status'] == 'success'
      @record = result['data']['object']
      msg = "Successfully created User #{@record['id']}, #{@record['login']}"
      flash[:success] = msg
      redirect '/users'
    else
      err_id, msg = parse_api_error(result)
      flash[:error] = msg
      case err_id
      when '1003' then
        # not found
        redirect '/users'
      when '1002' then
        # permission denied or quota exhausted
        redirect '/users'
      else
        # try again
        redirect '/users/new'
      end
    end
  end

  namespace'/:id' do
    get '/edit' do
      _dummy, @record = api_query("users/#{params['id']}")
      _dummy, @groups = api_query('groups')
      _dummy, @packages = api_query('packages')
      ui_edit('User',
              group_opts: 'group_select_options',
              package_opts: 'package_select_options')
    end

    post do
      update_params = {}

      # passwords must match
      passwd = params['password']
      unless passwd == params['password2']
        flash[:error] = 'Passwords must match'
        redirect "/users/#{params['id']}/edit"
      end

      pkgs = params['packages']
      update_params[:packages] = pkgs.map(&:to_i) unless pkgs.nil? || pkgs == ''

      update_params[:password] = passwd unless passwd.nil? || passwd == ''
      update_params[:group_id] = params['group_id'].to_i
      update_params[:name] = params['name']
      update_params[:login] = params['login']
      update_params[:contact_email] = params['contact_email']
      update_params[:enabled] = string_to_bool(params['enabled'])

      result = api_update("users/#{params['id']}", update_params)

      if result['status'] == 'success'
        msg = "Successfully updated User #{params['id']}, #{params['name']}"
        flash[:success] = msg
        @record = result['data']['object']
        redirect '/users'
      else
        s = result['status']
        e = result['error_id']
        m = result['message']
        msg = "#{s}: #{e}, #{m}"
        flash[:error] = msg
        case e
        when '1003' then
          # not found
          redirect '/users'
        when '1002' then
          # permission denied or quota exhausted
          redirect '/users'
        else
          # try again
          redirect "/users/#{params['id']}/edit"
        end
      end
    end

    get '/delete' do
      _dummy, record = api_query("users/#{params['id']}")
      @delete = {
        class_name: 'User',
        name: 'delete_user',
        endpoint: 'users',
        id: record['id'],
        detail: record['name']
      }
      ui_delete
    end

    post '/delete' do
      resource = "users/#{params['id']}"
      _dummy, record = api_query(resource)
      result = api_delete(resource)

      if result['status'] == 'success'
        msg = "Successfully deleted User #{record['id']} (#{record['name']})"
        flash[:success] = msg
      else
        s = result['status']
        e = result['error_id']
        m = result['message']
        msg = "#{s}: #{e}, #{m}"
        flash[:error] = msg
      end
      redirect '/users'
    end
  end
end
