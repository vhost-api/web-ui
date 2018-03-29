# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace '/groups' do
  before do
    @sidebar_title = 'Groups'
    @sidebar_elements = []
  end

  get do
    ui_output('groups')
  end

  namespace '/:id' do
    get '/edit' do
      _dummy, @record = api_query("groups/#{params['id']}")
      check_response(@record)
      ui_edit('Group')
    end

    post do
      update_params = {}
      update_params[:name] = params['name']
      update_params[:enabled] = string_to_bool(params['enabled'])

      result = api_update("groups/#{params['id']}", update_params)

      if result['status'] == 'success'
        msg = "Successfully updated Group #{params['id']}, #{params['name']}"
        flash[:success] = msg
        @record = result['data']['object']
        redirect '/groups'
      else
        s = result['status']
        e = result['error_id']
        m = result['message']
        msg = "#{s}: #{e}, #{m}"
        flash[:error] = msg
        case e
        when '1004' then
          # not found
          redirect '/groups'
        when '1003' then
          # permission denied or quota exhausted
          redirect '/groups'
        else
          # try again
          redirect "/groups/#{params['id']}/edit"
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
