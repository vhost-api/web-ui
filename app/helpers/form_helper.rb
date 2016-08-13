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
  def group_select_options
    return [] if @groups.nil? || @groups.empty?
    @groups.each_value.map do |g|
      opt = { value: g['id'], text: g['name'] }
      opt[:selected] = 'selected' if g['id'] == @record['id']
      opt
    end
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
    active_domain = @record['domain']['id']
    @domains.each_value.map do |d|
      opt = { value: d['id'], text: d['name'] }
      opt[:selected] = 'selected' if d['id'] == active_domain
      opt
    end
  end

  # @return [Hash]
  def mail_aliases_select_options
    return [] if @mail_aliases.nil? || @mail_aliases.empty?
    active_aliases = @record['mail_aliases'].map { |x| x['id'] }
    @mail_aliases.each_value.map do |a|
      opt = { value: a['id'], text: a['address'] }
      opt[:selected] = 'selected' if active_aliases.include?(a['id'])
      opt
    end
  end

  # @return [Hash]
  def mail_sources_select_options
    return [] if @mail_sources.nil? || @mail_sources.empty?
    active_sources = @record['mail_sources'].map { |x| x['id'] }
    @mail_sources.each_value.map do |s|
      opt = { value: s['id'], text: s['address'] }
      opt[:selected] = 'selected' if active_sources.include?(s['id'])
      opt
    end
  end
end
