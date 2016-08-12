# frozen_string_literal: true
namespace '/dns' do
  before do
    @sidebar_title = 'DNS'
    @sidebar_elements = %w(Domains Zones Templates)
  end

  get do
    haml :dnshome
  end

  namespace '/domains' do
    get do
      @domains = api_query('domains')
      haml :domains
    end
  end
end
