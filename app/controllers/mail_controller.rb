# frozen_string_literal: true
namespace '/mail' do
  before do
    @sidebar_title = 'Mail'
    @sidebar_elements = [
      { title: 'Help', link: '/mail', regex: %r{^/mail$} },
      { title: 'Accounts', link: '/mail/accounts', regex: %r{^/mail/accounts} },
      { title: 'Aliases', link: '/mail/aliases', regex: %r{^/mail/aliases} },
      { title: 'Sources', link: '/mail/sources', regex: %r{^/mail/sources} },
      { title: 'Forwardings', link: '/mail/forwardings',
        regex: %r{^/mail/forwardings} },
      { title: 'DKIM', link: '/mail/dkim', regex: %r{^/mail/dkim} }
    ]
  end

  get do
    haml :mailhome
  end

  namespace '/accounts' do
    get do
      ui_output(
        'mailaccounts',
        fields: %w(id enabled email realname receiving_enabled quota quotausage
                   quotausage_rel updated_at created_at).join(',')
      )
    end

    get '/new' do
      @domains = { '0' => { 'id' => 0, 'name' => 'Please select a domain...' } }
      _dummy, existing_domains = api_query('domains')
      @domains.merge!(existing_domains)
      _dummy, @mail_aliases = api_query('mailaliases')
      _dummy, @mail_sources = api_query('mailsources')
      ui_create('MailAccount',
                domain_opts: 'domain_select_options',
                mail_alias_opts: 'mail_aliases_select_options',
                mail_source_opts: 'mail_sources_select_options')
    end

    post do
      create_params = {}
      # passwords must match
      passwd = params['password']
      unless passwd == params['password2']
        flash[:error] = 'Passwords must match'
        redirect '/mail/accounts/new'
      end

      create_params[:password] = passwd unless passwd.nil? || passwd == ''

      create_params[:domain_id] = params['domain_id'].to_i
      _dummy, domain = api_query("domains/#{params['domain_id']}")

      create_params[:email] = [params['localpart'], domain['name']].join('@')

      create_params[:realname] = params['realname']

      %w(quota quota_sieve_script).each do |k|
        input = params[k].to_f
        mult = params["#{k}_unit"].to_i
        value = (input * mult).round(0)
        create_params[k.to_sym] = value
      end

      %w(quota_sieve_actions quota_sieve_redirects).each do |k|
        create_params[k.to_sym] = params[k].to_i
      end

      %w(receiving_enabled enabled).each do |k|
        create_params[k.to_sym] = if params[k].nil?
                                    false
                                  else
                                    string_to_bool(params[k])
                                  end
      end

      als = params['aliases']
      create_params[:aliases] = if als.nil? || als == ''
                                  []
                                else
                                  als.map(&:to_i)
                                end

      src = params['sources']
      create_params[:sources] = if src.nil? || src == ''
                                  []
                                else
                                  src.map(&:to_i)
                                end
      result = api_create('mailaccounts', create_params)

      flash_status = 'error'
      if result['status'] == 'success'
        @record = result['data']['object']
        msg = "Successfully created MailAcccount #{@record['id']}"
        msg += ", #{@record['email']}"
        flash_status = 'success'
      else
        err_id, msg, errors = parse_api_error(result)
      end

      if params['ajax'].nil?
        flash[flash_status.to_sym] = msg
        redirect '/mail/accounts'
      else
        reply = { status: flash_status, msg: msg, redirect: '/mail/accounts' }
        reply['error_id'] = err_id if errors
        reply['errors'] = errors if errors
        halt 200, reply.to_json
      end
    end

    namespace'/:id' do
      get '/edit' do
        _dummy, @record = api_query("mailaccounts/#{params['id']}")
        check_response(@record)
        _dummy, @domains = api_query('domains')
        _dummy, @mail_aliases = api_query('mailaliases')
        _dummy, @mail_sources = api_query('mailsources')
        ui_edit('MailAccount',
                domain_opts: 'domain_select_options',
                mail_alias_opts: 'mail_aliases_select_options',
                mail_source_opts: 'mail_sources_select_options')
      end

      post do
        upd_params = {}
        # passwords must match
        passwd = params['password']
        unless passwd == params['password2']
          flash[:error] = 'Passwords must match'
          redirect "/mail/accounts/#{params['id']}/edit"
        end

        upd_params[:password] = passwd unless passwd.nil? || passwd == ''

        upd_params[:domain_id] = params['domain_id'].to_i
        _dummy, domain = api_query("domains/#{params['domain_id']}")

        upd_params[:email] = [params['localpart'], domain['name']].join('@')

        upd_params[:realname] = params['realname']

        %w(quota quota_sieve_script).each do |k|
          input = params[k].to_f
          mult = params["#{k}_unit"].to_i
          value = (input * mult).round(0)
          upd_params[k.to_sym] = value
        end

        %w(quota_sieve_actions quota_sieve_redirects).each do |k|
          upd_params[k.to_sym] = params[k].to_i
        end

        %w(receiving_enabled enabled).each do |k|
          upd_params[k.to_sym] = if params[k].nil?
                                   false
                                 else
                                   string_to_bool(params[k])
                                 end
        end

        als = params['aliases']
        upd_params[:aliases] = if als.nil? || als == ''
                                 []
                               else
                                 als.map(&:to_i)
                               end

        src = params['sources']
        upd_params[:sources] = if src.nil? || src == ''
                                 []
                               else
                                 src.map(&:to_i)
                               end

        result = api_update("mailaccounts/#{params['id']}", upd_params)

        flash_status = 'error'
        if result['status'] == 'success'
          @record = result['data']['object']
          msg = "Successfully updated MailAcccount #{@record['id']}"
          msg += ", #{@record['email']}"
          flash_status = 'success'
        else
          err_id, msg, errors = parse_api_error(result)
        end

        if params['ajax'].nil?
          flash[flash_status.to_sym] = msg
          redirect '/mail/accounts'
        else
          reply = { status: flash_status, msg: msg, redirect: '/mail/accounts' }
          reply['error_id'] = err_id if errors
          reply['errors'] = errors if errors
          halt 200, reply.to_json
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
        ui_delete(ajax: params['ajax'].nil? ? false : true)
      end

      post '/delete' do
        resource = "mailaccounts/#{params['id']}"
        _dummy, record = api_query(resource)
        result = api_delete(resource)

        flash_status = 'error'
        if result['status'] == 'success'
          msg = "Successfully deleted MailAccount #{record['id']}"
          msg += " (#{record['email']})"
          flash_status = 'success'
        else
          _err_id, msg = parse_api_error(result)
        end

        if params['ajax'].nil?
          flash[flash_status.to_sym] = msg
          redirect '/mail/accounts'
        else
          halt 200, { status: flash_status, msg: msg }.to_json
        end
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

    get '/new' do
      @domains = { '0' => { 'id' => 0, 'name' => 'Please select a domain...' } }
      _dummy, existing_domains = api_query('domains')
      @domains.merge!(existing_domains)
      _dummy, @mail_accounts = api_query('mailaccounts')
      ui_create('MailAlias',
                domain_opts: 'domain_select_options',
                mail_account_opts: 'mail_accounts_select_options')
    end

    post do
      create_params = {}

      create_params[:domain_id] = params['domain_id'].to_i
      _dummy, domain = api_query("domains/#{params['domain_id']}")

      create_params[:address] = [params['localpart'], domain['name']].join('@')

      %w(enabled).each do |k|
        create_params[k.to_sym] = if params[k].nil?
                                    false
                                  else
                                    string_to_bool(params[k])
                                  end
      end

      acs = params['accounts']
      create_params[:dest] = if acs.nil? || acs == ''
                               []
                             else
                               acs.map(&:to_i)
                             end

      result = api_create('mailaliases', create_params)

      flash_status = 'error'
      if result['status'] == 'success'
        @record = result['data']['object']
        msg = "Successfully created MailAlias #{@record['id']}"
        msg += ", #{@record['address']}"
        flash_status = 'success'
      else
        err_id, msg, errors = parse_api_error(result)
      end

      if params['ajax'].nil?
        flash[flash_status.to_sym] = msg
        redirect '/mail/aliases'
      else
        reply = { status: flash_status, msg: msg, redirect: '/mail/aliases' }
        reply['error_id'] = err_id if errors
        reply['errors'] = errors if errors
        halt 200, reply.to_json
      end
    end

    namespace'/:id' do
      get '/edit' do
        _dummy, @record = api_query("mailaliases/#{params['id']}")
        check_response(@record)
        _dummy, @domains = api_query('domains')
        _dummy, @mail_accounts = api_query('mailaccounts')
        ui_edit('MailAlias',
                domain_opts: 'domain_select_options',
                mail_account_opts: 'mail_accounts_select_options')
      end

      post do
        upd_params = {}

        upd_params[:domain_id] = params['domain_id'].to_i
        _dummy, domain = api_query("domains/#{params['domain_id']}")

        upd_params[:address] = [params['localpart'], domain['name']].join('@')

        %w(enabled).each do |k|
          upd_params[k.to_sym] = if params[k].nil?
                                   false
                                 else
                                   string_to_bool(params[k])
                                 end
        end

        acs = params['accounts']
        upd_params[:dest] = if acs.nil? || acs == ''
                              []
                            else
                              acs.map(&:to_i)
                            end

        result = api_update("mailaliases/#{params['id']}", upd_params)

        flash_status = 'error'
        if result['status'] == 'success'
          @record = result['data']['object']
          msg = "Successfully updated MailAlias #{@record['id']}"
          msg += ", #{@record['address']}"
          flash_status = 'success'
        else
          err_id, msg, errors = parse_api_error(result)
        end

        if params['ajax'].nil?
          flash[flash_status.to_sym] = msg
          redirect '/mail/aliases'
        else
          reply = { status: flash_status, msg: msg, redirect: '/mail/aliases' }
          reply['error_id'] = err_id if errors
          reply['errors'] = errors if errors
          halt 200, reply.to_json
        end
      end

      get '/delete' do
        _dummy, record = api_query("mailaliases/#{params['id']}")
        @delete = {
          class_name: 'MailAlias',
          name: 'delete_mailalias',
          endpoint: 'mail/aliases',
          id: record['id'],
          detail: record['address']
        }
        ui_delete(ajax: params['ajax'].nil? ? false : true)
      end

      post '/delete' do
        resource = "mailaliases/#{params['id']}"
        _dummy, record = api_query(resource)
        result = api_delete(resource)

        flash_status = 'error'
        if result['status'] == 'success'
          msg = "Successfully deleted MailAlias #{record['id']}"
          msg += " (#{record['address']})"
          flash_status = 'success'
        else
          _err_id, msg = parse_api_error(result)
        end

        if params['ajax'].nil?
          flash[flash_status.to_sym] = msg
          redirect '/mail/aliases'
        else
          halt 200, { status: flash_status, msg: msg }.to_json
        end
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

    get '/new' do
      @domains = { '0' => { 'id' => 0, 'name' => 'Please select a domain...' } }
      _dummy, existing_domains = api_query('domains')
      @domains.merge!(existing_domains)
      _dummy, @mail_accounts = api_query('mailaccounts')
      ui_create('MailSource',
                domain_opts: 'domain_select_options',
                mail_account_opts: 'mail_accounts_select_options')
    end

    post do
      create_params = {}

      create_params[:domain_id] = params['domain_id'].to_i
      _dummy, domain = api_query("domains/#{params['domain_id']}")

      create_params[:address] = [params['localpart'], domain['name']].join('@')

      %w(enabled).each do |k|
        create_params[k.to_sym] = if params[k].nil?
                                    false
                                  else
                                    string_to_bool(params[k])
                                  end
      end

      acs = params['accounts']
      create_params[:src] = if acs.nil? || acs == ''
                              []
                            else
                              acs.map(&:to_i)
                            end

      result = api_create('mailsources', create_params)

      flash_status = 'error'
      if result['status'] == 'success'
        @record = result['data']['object']
        msg = "Successfully created MailSource #{@record['id']}"
        msg += ", #{@record['address']}"
        flash_status = 'success'
      else
        err_id, msg, errors = parse_api_error(result)
      end

      if params['ajax'].nil?
        flash[flash_status.to_sym] = msg
        redirect '/mail/sources'
      else
        reply = { status: flash_status, msg: msg, redirect: '/mail/sources' }
        reply['error_id'] = err_id if errors
        reply['errors'] = errors if errors
        halt 200, reply.to_json
      end
    end

    namespace'/:id' do
      get '/edit' do
        _dummy, @record = api_query("mailsources/#{params['id']}")
        check_response(@record)
        _dummy, @domains = api_query('domains')
        _dummy, @mail_accounts = api_query('mailaccounts')
        ui_edit('MailSource',
                domain_opts: 'domain_select_options',
                mail_account_opts: 'mail_accounts_select_options')
      end

      post do
        upd_params = {}

        upd_params[:domain_id] = params['domain_id'].to_i
        _dummy, domain = api_query("domains/#{params['domain_id']}")

        upd_params[:address] = [params['localpart'], domain['name']].join('@')

        %w(enabled).each do |k|
          upd_params[k.to_sym] = if params[k].nil?
                                   false
                                 else
                                   string_to_bool(params[k])
                                 end
        end

        acs = params['accounts']
        upd_params[:src] = if acs.nil? || acs == ''
                             []
                           else
                             acs.map(&:to_i)
                           end

        result = api_update("mailsources/#{params['id']}", upd_params)

        flash_status = 'error'
        if result['status'] == 'success'
          @record = result['data']['object']
          msg = "Successfully updated MailSource #{@record['id']}"
          msg += ", #{@record['address']}"
          flash_status = 'success'
        else
          err_id, msg, errors = parse_api_error(result)
        end

        if params['ajax'].nil?
          flash[flash_status.to_sym] = msg
          redirect '/mail/sources'
        else
          reply = { status: flash_status, msg: msg, redirect: '/mail/sources' }
          reply['error_id'] = err_id if errors
          reply['errors'] = errors if errors
          halt 200, reply.to_json
        end
      end

      get '/delete' do
        _dummy, record = api_query("mailsources/#{params['id']}")
        @delete = {
          class_name: 'MailSource',
          name: 'delete_mailsource',
          endpoint: 'mail/sources',
          id: record['id'],
          detail: record['address']
        }
        ui_delete(ajax: params['ajax'].nil? ? false : true)
      end

      post '/delete' do
        resource = "mailsources/#{params['id']}"
        _dummy, record = api_query(resource)
        result = api_delete(resource)

        flash_status = 'error'
        if result['status'] == 'success'
          msg = "Successfully deleted MailSource #{record['id']}"
          msg += " (#{record['address']})"
          flash_status = 'success'
        else
          _err_id, msg = parse_api_error(result)
        end

        if params['ajax'].nil?
          flash[flash_status.to_sym] = msg
          redirect '/mail/sources'
        else
          halt 200, { status: flash_status, msg: msg }.to_json
        end
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

    get '/new' do
      @domains = { '0' => { 'id' => 0, 'name' => 'Please select a domain...' } }
      _dummy, existing_domains = api_query('domains')
      @domains.merge!(existing_domains)
      ui_create('MailForwarding', domain_opts: 'domain_select_options')
    end

    post do
      create_params = {}

      create_params[:domain_id] = params['domain_id'].to_i
      _dummy, domain = api_query("domains/#{params['domain_id']}")

      create_params[:address] = [params['localpart'], domain['name']].join('@')
      create_params[:destinations] = params['destinations']

      %w(enabled).each do |k|
        create_params[k.to_sym] = if params[k].nil?
                                    false
                                  else
                                    string_to_bool(params[k])
                                  end
      end

      result = api_create('mailforwardings', create_params)

      flash_status = 'error'
      if result['status'] == 'success'
        @record = result['data']['object']
        msg = "Successfully created MailForwarding #{@record['id']}"
        msg += ", #{@record['address']}"
        flash_status = 'success'
      else
        err_id, msg, errors = parse_api_error(result)
      end

      if params['ajax'].nil?
        flash[flash_status.to_sym] = msg
        redirect '/mail/forwardings'
      else
        reply = { status: flash_status, msg: msg, redirect: '/mail/forwardings' }
        reply['error_id'] = err_id if errors
        reply['errors'] = errors if errors
        halt 200, reply.to_json
      end
    end

    namespace'/:id' do
      get '/edit' do
        _dummy, @record = api_query("mailforwardings/#{params['id']}")
        check_response(@record)
        _dummy, @domains = api_query('domains')
        ui_edit('MailForwarding',
                domain_opts: 'domain_select_options')
      end

      post do
        upd_params = {}

        upd_params[:domain_id] = params['domain_id'].to_i
        _dummy, domain = api_query("domains/#{params['domain_id']}")

        upd_params[:address] = [params['localpart'], domain['name']].join('@')
        upd_params[:destinations] = params['destinations']

        %w(enabled).each do |k|
          upd_params[k.to_sym] = if params[k].nil?
                                   false
                                 else
                                   string_to_bool(params[k])
                                 end
        end

        result = api_update("mailforwardings/#{params['id']}", upd_params)

        flash_status = 'error'
        if result['status'] == 'success'
          @record = result['data']['object']
          msg = "Successfully updated MailForwarding #{@record['id']}"
          msg += ", #{@record['address']}"
          flash_status = 'success'
        else
          err_id, msg, errors = parse_api_error(result)
        end

        if params['ajax'].nil?
          flash[flash_status.to_sym] = msg
          redirect '/mail/forwardings'
        else
          reply = { status: flash_status, msg: msg, redirect: '/mail/forwardings' }
          reply['error_id'] = err_id if errors
          reply['errors'] = errors if errors
          halt 200, reply.to_json
        end
      end

      get '/delete' do
        _dummy, record = api_query("mailforwardings/#{params['id']}")
        @delete = {
          class_name: 'MailForwarding',
          name: 'delete_mailforwarding',
          endpoint: 'mail/forwardings',
          id: record['id'],
          detail: record['address']
        }
        ui_delete(ajax: params['ajax'].nil? ? false : true)
      end

      post '/delete' do
        resource = "mailforwardings/#{params['id']}"
        _dummy, record = api_query(resource)
        result = api_delete(resource)

        flash_status = 'error'
        if result['status'] == 'success'
          msg = "Successfully deleted MailForwarding #{record['id']}"
          msg += " (#{record['address']})"
          flash_status = 'success'
        else
          _err_id, msg = parse_api_error(result)
        end

        if params['ajax'].nil?
          flash[flash_status.to_sym] = msg
          redirect '/mail/forwardings'
        else
          halt 200, { status: flash_status, msg: msg }.to_json
        end
      end
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
        ui_delete(ajax: params['ajax'].nil? ? false : true)
      end

      post '/delete' do
        resource = "dkims/#{params['id']}"
        _dummy, record = api_query(resource)
        result = api_delete(resource)

        flash_status = 'error'
        if result['status'] == 'success'
          msg = "Successfully deleted DKIM #{record['id']}"
          msg += " (#{record['selector']})"
          flash_status = 'success'
        else
          _err_id, msg = parse_api_error(result)
        end

        if params['ajax'].nil?
          flash[flash_status.to_sym] = msg
          redirect '/mail/dkim'
        else
          halt 200, { status: flash_status, msg: msg }.to_json
        end
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
        ui_delete(ajax: params['ajax'].nil? ? false : true)
      end

      post '/delete' do
        resource = "dkimsignings/#{params['id']}"
        _dummy, record = api_query(resource)
        result = api_delete(resource)

        flash_status = 'error'
        if result['status'] == 'success'
          msg = "Successfully deleted DkimSigning #{record['id']}"
          msg += " (#{record['author']})"
          flash_status = 'success'
        else
          _err_id, msg = parse_api_error(result)
        end

        if params['ajax'].nil?
          flash[flash_status.to_sym] = msg
          redirect '/mail/dkim'
        else
          halt 200, { status: flash_status, msg: msg }.to_json
        end
      end
    end
  end
end
