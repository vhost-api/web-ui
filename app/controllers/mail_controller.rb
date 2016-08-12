# frozen_string_literal: true
namespace '/mail' do
  before do
    @sidebar_title = 'Mail'
    @sidebar_elements = %w(Domains Accounts Aliases Sources Forwardings DKIM)
  end

  get do
    haml :mailhome
  end

  namespace '/domains' do
    get do
      ui_output('domains')
    end
  end

  namespace '/accounts' do
    get do
      ui_output('mailaccounts')
    end

    namespace'/:id' do
      get '/edit' do
        _dummy, @domains = api_query('domains')
        _dummy, @mailaliases = api_query('mailaliases')
        _dummy, @mailsources = api_query('mailsources')
        ui_edit("mailaccounts/#{params['id']}/edit")
      end

      post do
        update_params = {}
        # passwords must match
        passwd = params['password']
        unless passwd == params['password2']
          flash[:error] = 'Passwords must match'
          redirect "/mail/accounts/#{params['id']}/edit"
        end

        update_params[:password] = passwd unless passwd.nil? || passwd == ''

        update_params[:domain_id] = params['domain_id'].to_i
        %w(realname email quota quota_sieve_script quota_sieve_actions
           quota_sieve_redirects).each do |k|
          update_params[k.to_sym] = params[k]
        end
        %w(receiving_enabled enabled).each do |k|
          update_params[k.to_sym] = if params[k].nil?
                                      false
                                    else
                                      string_to_bool(params[k])
                                    end
        end

        result = api_update("mailaccounts/#{params['id']}", update_params)

        if result['status'] == 'success'
          msg = "Successfully updated MailAcccount #{params['id']}"
          msg += ", #{params['email']}"
          flash[:success] = msg
          @record = result['data']['object']
          redirect '/mail/accounts'
        else
          s = result['status']
          e = result['error_id']
          m = result['message']
          msg = "#{s}: #{e}, #{m}"
          flash[:error] = msg
          case e
          when '1003' then
            # not found
            redirect '/mail/accounts'
          when '1002' then
            # permission denied or quota exhausted
            redirect '/mail/accounts'
          else
            # try again
            redirect "/mail/accounts/#{params['id']}/edit"
          end
        end
      end
    end
  end

  namespace '/aliases' do
    get do
      ui_output('mailaliases')
    end
  end

  namespace '/sources' do
    get do
      ui_output('mailaliases')
    end
  end

  namespace '/dkim' do
    get do
      @dkims = api_query('dkims')
      @dkimsignings = api_query('dkimsignings')
      haml :dkim
    end
  end
end
