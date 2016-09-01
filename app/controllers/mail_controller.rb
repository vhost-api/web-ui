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
      ui_output(
        'domains',
        fields: %w(id name mail_enabled dns_enabled created_at updated_at
                   enabled user).join(',')
      )
    end
  end

  namespace '/accounts' do
    get do
      ui_output(
        'mailaccounts',
        fields: %w(id enabled email realname receiving_enabled quota quotausage
                   quotausage_rel).join(',')
      )
    end

    get '/new' do
      @domains = { '0' => { 'id' => 0, 'name' => 'Please select a domain...' } }
      _dummy, existing_domains = api_query('domains')
      @domains.merge!(existing_domains)
      ui_create('MailAccount', domain_opts: 'domain_select_options')
    end

    post do
      # TODO: mail_aliases/mail_sources stuff
      create_params = {}
      # passwords must match
      passwd = params['password']
      unless passwd == params['password2']
        flash[:error] = 'Passwords must match'
        redirect "/mail/accounts/#{params['id']}/edit"
      end

      create_params[:password] = passwd unless passwd.nil? || passwd == ''

      _dummy, domain = api_query("domains/#{params['domain_id']}")
      create_params[:domain_id] = domain['id'].to_i
      create_params[:email] = "#{params['localpart']}@#{domain['name']}"

      %w(realname quota quota_sieve_script quota_sieve_actions
         quota_sieve_redirects).each do |k|
        create_params[k.to_sym] = params[k]
      end
      %w(receiving_enabled enabled).each do |k|
        create_params[k.to_sym] = if params[k].nil?
                                    false
                                  else
                                    string_to_bool(params[k])
                                  end
      end

      result = api_create('mailaccounts', create_params)

      if result['status'] == 'success'
        @record = result['data']['object']
        msg = "Successfully created MailAcccount #{@record['id']}"
        msg += ", #{@record['email']}"
        flash[:success] = msg
        redirect '/mail/accounts'
      else
        err_id, msg = parse_api_error(result)
        flash[:error] = msg
        case err_id
        when '1003' then
          # not found
          redirect '/mail/accounts'
        when '1002' then
          # permission denied or quota exhausted
          redirect '/mail/accounts'
        else
          # try again
          redirect '/mail/accounts/new'
        end
      end
    end

    namespace'/:id' do
      get '/edit' do
        _dummy, @record = api_query("mailaccounts/#{params['id']}")
        d_id = @record['domain']['id']
        _dummy, @domains = api_query('domains')
        _dummy, @mail_aliases = api_query("mailaliases?q[domain_id]=#{d_id}")
        _dummy, @mail_sources = api_query("mailsources?q[domain_id]=#{d_id}")
        ui_edit('MailAccount',
                domain_opts: 'domain_select_options',
                mail_alias_opts: 'mail_aliases_select_options',
                mail_source_opts: 'mail_sources_select_options')
      end

      post do
        p(params)
        update_params = {}
        # passwords must match
        passwd = params['password']
        unless passwd == params['password2']
          flash[:error] = 'Passwords must match'
          redirect "/mail/accounts/#{params['id']}/edit"
        end

        update_params[:password] = passwd unless passwd.nil? || passwd == ''

        update_params[:domain_id] = params['domain_id'].to_i
        _dummy, domain = api_query("domains/#{params['domain_id']}")

        update_params[:email] = [params['localpart'], domain['name']].join('@')

        update_params[:realname] = params['realname']

        %w(quota quota_sieve_script).each do |k|
          input = params[k].to_f
          mult = params["#{k}_unit"].to_i
          value = (input * mult).round(0)
          update_params[k.to_sym] = value
        end

        %w(quota_sieve_actions quota_sieve_redirects).each do |k|
          update_params[k.to_sym] = params[k].to_i
        end

        %w(receiving_enabled enabled).each do |k|
          update_params[k.to_sym] = if params[k].nil?
                                      false
                                    else
                                      string_to_bool(params[k])
                                    end
        end

        als = params['aliases']
        update_params[:aliases] = als.map(&:to_i) unless als.nil? || als == ''

        src = params['sources']
        update_params[:sources] = src.map(&:to_i) unless src.nil? || src == ''

        p(update_params)
        result = api_update("mailaccounts/#{params['id']}", update_params)

        if result['status'] == 'success'
          msg = "Successfully updated MailAcccount #{params['id']}"
          msg += ", #{params['email']}"
          flash[:success] = msg
          @record = result['data']['object']
          redirect '/mail/accounts'
        else
          err_id, msg = parse_api_error(result)
          flash[:error] = msg
          case err_id
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

      get '/delete' do
        _dummy, record = api_query("mailaccounts/#{params['id']}")
        @delete = {
          class_name: 'MailAcccount',
          name: 'delete_mailaccount',
          endpoint: 'mail/accounts',
          id: record['id'],
          detail: record['email']
        }
        ui_delete
      end

      post '/delete' do
        resource = "mailaccounts/#{params['id']}"
        _dummy, record = api_query(resource)
        result = api_delete(resource)

        if result['status'] == 'success'
          msg = "Successfully deleted MailAccount #{record['id']}"
          msg += " (#{record['email']})"
          flash[:success] = msg
        else
          _err_id, msg = parse_api_error(result)
          flash[:error] = msg
        end
        redirect '/mail/accounts'
      end
    end
  end

  namespace '/aliases' do
    get do
      ui_output(
        'mailaliases',
        fields: %w(id address created_at updated_at enabled domain
                   mail_accounts).join(',')
      )
    end

    namespace'/:id' do
      get '/delete' do
        _dummy, record = api_query("mailaliases/#{params['id']}")
        @delete = {
          class_name: 'MailAlias',
          name: 'delete_mailalias',
          endpoint: 'mail/aliases',
          id: record['id'],
          detail: record['address']
        }
        ui_delete
      end

      post '/delete' do
        resource = "mailaliases/#{params['id']}"
        _dummy, record = api_query(resource)
        result = api_delete(resource)

        if result['status'] == 'success'
          msg = "Successfully deleted MailAlias #{record['id']}"
          msg += " (#{record['address']})"
          flash[:success] = msg
        else
          s = result['status']
          e = result['error_id']
          m = result['message']
          msg = "#{s}: #{e}, #{m}"
          flash[:error] = msg
        end
        redirect '/mail/aliases'
      end
    end
  end

  namespace '/sources' do
    get do
      ui_output(
        'mailsources',
        fields: %w(id address created_at updated_at enabled domain
                   mail_accounts).join(',')
      )
    end

    namespace'/:id' do
      get '/delete' do
        _dummy, record = api_query("mailsources/#{params['id']}")
        @delete = {
          class_name: 'MailSource',
          name: 'delete_mailsource',
          endpoint: 'mail/sources',
          id: record['id'],
          detail: record['address']
        }
        ui_delete
      end

      post '/delete' do
        resource = "mailsources/#{params['id']}"
        _dummy, record = api_query(resource)
        result = api_delete(resource)

        if result['status'] == 'success'
          msg = "Successfully deleted MailSource #{record['id']}"
          msg += " (#{record['address']})"
          flash[:success] = msg
        else
          s = result['status']
          e = result['error_id']
          m = result['message']
          msg = "#{s}: #{e}, #{m}"
          flash[:error] = msg
        end
        redirect '/mail/sources'
      end
    end
  end

  namespace '/forwardings' do
    get do
      ui_output(
        'mailforwardings',
        fields: %w(id address created_at updated_at enabled domain
                   destinations).join(',')
      )
    end
  end

  namespace '/dkim' do
    get do
      _dummy, @dkims = api_query(
        'dkims',
        fields: 'id,selector,created_at,updated_at,enabled,domain,dkim_signings'
      )
      _dummy, @dkimsignings = api_query(
        'dkimsignings',
        fields: 'id,author,created_at,updated_at,enabled,dkim'
      )
      haml :dkim
    end

    namespace'/:id' do
      get '/delete' do
        _dummy, record = api_query("dkims/#{params['id']}")
        txt = "Domain: #{record['domain']['name']}"
        txt += ", Selector: #{record['selector']}"
        @delete = {
          class_name: 'DKIM',
          name: 'delete_dkim',
          endpoint: 'mail/dkim',
          id: record['id'],
          detail: txt
        }
        ui_delete
      end

      post '/delete' do
        resource = "dkims/#{params['id']}"
        _dummy, record = api_query(resource)
        result = api_delete(resource)

        if result['status'] == 'success'
          msg = "Successfully deleted DKIM #{record['id']}"
          msg += " (#{record['selector']})"
          flash[:success] = msg
        else
          s = result['status']
          e = result['error_id']
          m = result['message']
          msg = "#{s}: #{e}, #{m}"
          flash[:error] = msg
        end
        redirect '/mail/dkim'
      end
    end
  end

  namespace '/dkimsigning' do
    namespace'/:id' do
      get '/delete' do
        _dummy, record = api_query("dkimsignings/#{params['id']}")
        txt = "Author: #{record['author']}"
        txt += ", DKIM ID: #{record['dkim']['id']}"
        @delete = {
          class_name: 'DkimSigning',
          name: 'delete_dkimsigning',
          endpoint: 'mail/dkimsigning',
          id: record['id'],
          detail: txt
        }
        ui_delete
      end

      post '/delete' do
        resource = "dkimsignings/#{params['id']}"
        _dummy, record = api_query(resource)
        result = api_delete(resource)

        if result['status'] == 'success'
          msg = "Successfully deleted DkimSigning #{record['id']}"
          msg += " (Author: #{record['author']}"
          msg += ", DKIM ID: #{record['dkim']['id']})"
          flash[:success] = msg
        else
          s = result['status']
          e = result['error_id']
          m = result['message']
          msg = "#{s}: #{e}, #{m}"
          flash[:error] = msg
        end
        redirect '/mail/dkim'
      end
    end
  end
end
