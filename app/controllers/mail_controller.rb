# frozen_string_literal: true
namespace '/mail' do
  get do
    'This ALWAYS redirects to /login, no matter what'
  end
end

namespace '/mails' do
  get do
    'This works'
  end
end

# namespace '/mail' do
# before do
# p '--- before (/mail) ---'
# p session.to_hash
# p session[:user].inspect
# p request.cookies.inspect
# @sidebar_title = 'Mail'
# @sidebar_elements = %w(Domains Accounts Aliases Sources Forwardings DKIM)
# end

# get do
# haml :mailhome
# end

# namespace '/domains' do
# get do
# ui_output('domains')
# end
# end

# namespace '/accounts' do
# get do
# ui_output('mailaccounts')
# end
# end

# namespace '/aliases' do
# get do
# ui_output('mailaliases')
# end
# end

# namespace '/sources' do
# get do
# ui_output('mailaliases')
# end
# end

# namespace '/dkim' do
# get do
# @dkims = api_query('dkims')
# @dkimsignings = api_query('dkimsignings')
# haml :dkim
# end
# end
# end
