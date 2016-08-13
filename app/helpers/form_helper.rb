# frozen_string_literal: true
# collection of form helpers
module FormHelpers
  # @param class_name [String]
  # @param options_helpers [Hash]
  # @return [Hash]
  def form_content(class_name, options_helpers = {})
    klass = Object.const_get(class_name)
    object = klass.new(symbolize_hash(@record))
    options_helpers.each do |opt, attr|
      object.public_send("#{opt}=", public_send(attr))
    end
    object.field_set
  end

  # @return [Hash]
  def user_select_options
    return [] if @users.nil? || @users.empty?
    @users.each_value.map do |u|
      opt = { value: u['id'], text: u['name'] }
      opt[:selected] = 'selected' if u['id'] == @record['id']
      opt
    end
  end

  # @return [Hash]
  def domain_select_options
    return [] if @domains.nil? || @domains.empty?
    result = []
    @domains.each_value do |d|
      opt = { value: d['id'], text: d['name'] }
      opt[:selected] = 'selected' if d['id'] == @record['id']
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
end
