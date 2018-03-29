# frozen_string_literal: true

namespace '/dns' do
  before do
    @sidebar_title = 'DNS'
    @sidebar_elements = [
      { title: 'Dashboard', link: '/dns', regex: %r{^/dns$} },
      { title: 'Zones', link: '/dns/zones', regex: %r{^/dns/zones} },
      { title: 'Templates', link: '/dns/templates', regex: %r{^/dns/templates} }
    ]
  end

  get do
    haml :dnshome
  end
end
