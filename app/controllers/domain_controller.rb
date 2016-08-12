# frozen_string_literal: true
namespace '/domains' do
  before do
    p '--- before (/domains) ---'
    p session.to_hash
    @sidebar_title = 'Domains'
    @sidebar_elements = []
  end

  get do
    ui_output('domains')
  end

  namespace'/:id' do
    get '/edit' do
      _dummy, @users = api_query('users')
      ui_edit(request.path_info.sub(%r{^/}, ''))
    end

    post do
      update_params = {}
      update_params[:user_id] = params['user_id'].to_i
      update_params[:name] = params['name']
      %w(mail_enabled dns_enabled enabled).each do |k|
        update_params[k.to_sym] = if params[k].nil?
                                    false
                                  else
                                    string_to_bool(params[k])
                                  end
      end

      result = api_update("domains/#{params['id']}", update_params)

      if result['status'] == 'success'
        msg = "Successfully updated Domain #{params['id']}, #{params['name']}"
        flash[:success] = msg
        @record = result['data']['object']
        redirect '/domains'
      else
        s = result['status']
        e = result['error_id']
        m = result['message']
        msg = "#{s}: #{e}, #{m}"
        flash[:error] = msg
        case e
        when '1003' then
          # not found
          redirect '/domains'
        when '1002' then
          # permission denied or quota exhausted
          redirect '/domains'
        else
          # try again
          redirect "/domains/#{params['id']}/edit"
        end
      end
    end
  end
end
