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

  namespace'/:id' do
    get '/edit' do
      _dummy, @record = api_query("users/#{params['id']}")
      _dummy, @groups = api_query('groups')
      ui_edit('User', group_opts: 'group_select_options')
    end

    post do
      update_params = {}

      # passwords must match
      passwd = params['password']
      unless passwd == params['password2']
        flash[:error] = 'Passwords must match'
        redirect "/users/#{params['id']}/edit"
      end

      update_params[:password] = passwd unless passwd.nil? || passwd == ''
      update_params[:group_id] = params['group_id'].to_i
      update_params[:name] = params['name']
      update_params[:login] = params['login']
      update_params[:contact_email] = params['contact_email']
      update_params[:enabled] = string_to_bool(params['enabled'])

      # quota stuff
      params.each_key do |k|
        update_params[k.to_sym] = params[k] if k =~ %r{^quota}
      end

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
  end
end
