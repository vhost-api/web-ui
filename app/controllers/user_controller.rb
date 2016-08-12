# frozen_string_literal: true
namespace '/users' do
  before do
    @sidebar_title = 'Users'
    @sidebar_elements = []
  end

  get do
    ui_output('users')
  end
end
