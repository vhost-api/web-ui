# frozen_string_literal: true
# collection of helpers for the user interface
module UIHelpers
  # @param endpoint [String]
  def ui_output(endpoint)
    response_digest, @result = api_query(endpoint)
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
end
