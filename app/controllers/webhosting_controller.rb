# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace '/webhosting' do
  before do
    @sidebar_title = 'Webhosting'
    @sidebar_elements = [
      { title: 'Dashboard', link: '/webhosting', regex: %r{^/webhosting$} },
      { title: 'VHosts', link: '/webhosting/vhosts',
        regex: %r{^/webhosting/vhosts} },
      { title: 'SFTP Users', link: '/webhosting/sftpusers',
        regex: %r{^/webhosting/sftusers} },
      { title: 'Shell Users', link: '/webhosting/shellusers',
        regex: %r{^/webhosting/shellusers} }
    ]
  end

  get do
    @phpruntimes = api_query('phpruntimes')
    @ipv4addresses = api_query('ipv4addresses')
    @ipv6addresses = api_query('ipv6addresses')
    haml :webhostinghome
  end

  namespace '/vhosts' do
    get do
      @vhosts = api_query('vhosts')
      haml :vhosts
    end
  end

  namespace '/sftpusers' do
    get do
      @sftpusers = api_query('sftpusers')
      haml :sftpusers
    end
  end

  namespace '/shellusers' do
    get do
      @shellusers = api_query('shellusers')
      haml :shellusers
    end
  end
end
# rubocop:enable Metrics/BlockLength
