# frozen_string_literal: true
namespace '/dns' do
  before do
    @sidebar_title = 'DNS'
    @sidebar_elements = [
      { title: 'Dashboard', link: '/dns' },
      { title: 'Zones', link: '/dns/zones' },
      { title: 'Templates', link: '/dns/templates' }
    ]
  end

  get do
    haml :dnshome
  end
end
