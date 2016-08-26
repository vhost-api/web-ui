# frozen_string_literal: true
# collection of helpers for the user interface
module UIHelpers
  # @param endpoint [String]
  # rubocop:disable Metrics/AbcSize
  def ui_output(endpoint, params = {})
    response_digest, @result = api_query(endpoint, params)
    if @result.is_a?(Hash) && @result.key?(:code)
      status @result[:code]
      halt haml :api_error if @result[:code].to_s =~ %r{(4|5)[0-9]{2}}
    end
    # only send etag along if there are no flash messages
    # otherwise they won't disappear on normal reload due to 304
    etag response_digest if session[:flash].nil? || session[:flash].empty?
    haml endpoint.to_sym
  end

  # @param class_name [String]
  def ui_edit(class_name, options_helpers = {})
    @form = form_content(class_name, options_helpers)
    haml "edit_#{class_name.downcase}".to_sym
  end

  def ui_delete
    haml :delete_template
  end

  # @param class_name [String]
  def ui_create(class_name, options_helpers = {})
    @form = form_content(class_name, options_helpers)
    haml "new_#{class_name.downcase}".to_sym
  end

  def session_expired
    session[:user] = nil
    flash[:error] = 'Session expired, please login again'
    redirect '/login'
  end

  def reseller?
    return false if @user.nil?
    return true if @user[:group] == 'reseller'
    false
  end

  def admin?
    return false if @user.nil?
    return true if @user[:group] == 'admin'
    false
  end
end
