# frozen_string_literal: true
# @param endpoint [String]
def ui_output(endpoint)
  response_digest, @result = api_query(endpoint)
  # only send etag along if there are no flash messages
  # otherwise they won't disappear on normal reload due to 304
  etag response_digest if session[:flash].nil? || session[:flash].empty?
  haml endpoint.to_sym
end

# @param resource [String]
def ui_edit(resource)
  halt 400 if resource.nil? || !resource.count('/').eql?(2)
  endpoint, res_id, _dummy = resource.split('/')
  _dummy, @record = api_query([endpoint, res_id].join('/'))
  @form = form_content(@record, endpoint)
  haml "edit_#{endpoint[0..-2]}".to_sym
end

# @param record [Hash]
# @param endpoint [Hash]
# @return [Hash]
def form_content(record, endpoint)
  send("generate_#{endpoint[0..-2]}_form", record)
end

# @param label [String]
# @param name [String]
# @param value [Boolean]
# @return [Hash]
def checkbox_element(label, name, value)
  element = { label: label, type: 'checkbox', name: name }
  element[:checked] = 'checked' if value
  element
end

# @param label [String]
# @param name [String]
# @param value [Fixnum]
# @param options [Hash]
# @return [Hash]
def select_element(label, name, value, options)
  element = { label: label, type: 'select', name: name }
  element[:options] = send("#{name[0..-4]}_select_options", value, options)
  element
end

# @param value [Hash]
# @param options [Hash]
# @return [Hash]
def user_select_options(selected, users)
  result = []
  result.push(
    value: selected['id'], text: selected['name'], selected: 'selected'
  )
  users.each do |u|
    result.push(value: u[1]['id'], text: u[1]['name'])
  end
  result
end

# @param value [Hash]
# @param options [Hash]
# @return [Hash]
def domain_select_options(selected, domains)
  result = []
  result.push(
    value: selected['id'], text: selected['name'], selected: 'selected'
  )
  domains.each do |d|
    result.push(value: d[1]['id'], text: d[1]['name'])
  end
  result
end

# @param label [String]
# @param name [String]
# @param value [String]
# @return [Hash]
def text_element(label, name, value)
  { label: label, type: 'text', name: name, value: value }
end

# @param label [String]
# @param name [String]
# @return [Hash]
def password_element(label, name)
  { label: label, type: 'password', name: name, placeholder: 'Password' }
end

# @param domain [Hash]
# @return [Hash]
def generate_domain_form(domain)
  fdata = { hidden_fields: [], visible_fields: [] }
  domain.each_pair do |key, value|
    field = domain_form_visible_field(key.to_s, value)
    fdata[:visible_fields].push(field) unless field.nil?
  end
  fdata
end

# @param key [String]
# @param value [Boolean, String, Hash, Fixnum]
def domain_form_visible_field(key, value)
  result = nil
  case key
  when %r{(id|ed_at$)} then nil
  when %r{enabled$} then result = checkbox_element(key, key, value)
  when %r{(user)} then
    result = select_element(key, "#{key}_id", value, @users)
  else result = text_element(key, key, value)
  end
  result
end

# @param domain [Hash]
# @return [Hash]
def generate_mailaccount_form(mailaccount)
  fdata = { hidden_fields: [], visible_fields: [] }
  mailaccount.each_pair do |key, value|
    field = mailaccount_form_visible_field(key.to_s, value)
    fdata[:visible_fields].push(field) unless field.nil?
  end
  fdata[:visible_fields].push(password_element('Password', 'password'))
  fdata
end

# @param key [String]
# @param value [Boolean, String, Hash, Fixnum]
def mailaccount_form_visible_field(key, value)
  result = nil
  case key
  when %r{(id|ed_at$)} then nil
  when %r{enabled$} then result = checkbox_element(key, key, value)
  when %r{(domain)} then
    result = select_element(key, "#{key}_id", value, @domains)
  else result = text_element(key, key, value)
  end
  result
end
