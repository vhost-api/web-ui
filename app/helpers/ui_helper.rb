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

# @param label [String]
# @param name [String]
# @param value [Fixnum]
# @param options [Hash]
# @return [Hash]
def select_multi_element(label, name, value, options)
  element = { label: label, type: 'select', name: name, multiple: true }
  element[:options] = send("#{name[0..-4]}_select_options", value, options)
  element
end

# @param selected [Hash]
# @param options [Hash]
# @return [Hash]
def user_select_options(selected, users)
  result = []
  users.each_value do |u|
    opt = if u['id'] == selected['id']
            { value: u['id'], text: u['name'], selected: 'selected' }
          else
            { value: u['id'], text: u['name'] }
          end
    result.push(opt)
  end
  result
end

# @param selected [Hash]
# @param options [Hash]
# @return [Hash]
def domain_select_options(selected, domains)
  result = []
  domains.each_value do |d|
    opt = if d['id'] == selected['id']
            { value: d['id'], text: d['name'], selected: 'selected' }
          else
            { value: d['id'], text: d['name'] }
          end
    result.push(opt)
  end
  result
end

# @param selected [Array(Hash)]
# @param options [Hash]
# @return [Hash]
def mail_aliases_select_options(selected, mailaliases)
  result = []
  mailaliases.each_value do |a|
    opt = if selected.map(&:values).map(&:first).include?(a['id'])
            { value: a['id'], text: a['address'], selected: 'selected' }
          else
            { value: a['id'], text: a['address'] }
          end
    result.push(opt)
  end
  result
end

# @param selected [Array(Hash)]
# @param options [Hash]
# @return [Hash]
def mail_sources_select_options(selected, mailsources)
  result = []
  mailsources.each_value do |s|
    opt = if selected.map(&:values).map(&:first).include?(s['id'])
            { value: s['id'], text: s['address'], selected: 'selected' }
          else
            { value: s['id'], text: s['address'] }
          end
    result.push(opt)
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
  fdata[:visible_fields].push(password_element('Password', 'password'))
  fdata[:visible_fields].push(password_element('Confirm Password', 'password2'))
  mailaccount.each_pair do |key, value|
    field = mailaccount_form_visible_field(key.to_s, value)
    fdata[:visible_fields].push(field) unless field.nil?
  end
  fdata
end

# @param k [String]
# @param v [Boolean, String, Hash, Fixnum]
def mailaccount_form_visible_field(k, v)
  case k
  when %r{(id|ed_at$|usage($|_rel$)|customer)} then nil
  when %r{enabled$} then result = checkbox_element(k, k, v)
  when %r{(mail_aliases)} then
    result = select_multi_element(k, "#{k}_id", v, @mailaliases)
  when %r{(mail_sources)} then
    result = select_multi_element(k, "#{k}_id", v, @mailsources)
  when %r{(domain)} then result = select_element(k, "#{k}_id", v, @domains)
  else result = text_element(k, k, v)
  end
  result
end
