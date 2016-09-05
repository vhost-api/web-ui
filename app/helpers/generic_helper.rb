# frozen_string_literal: true
# collection of generic helpers
module GenericHelpers
  # @param hash [Hash]
  # @return [Hash]
  def symbolize_hash(hash)
    return {} if hash.nil? || hash.empty?
    hash.reduce({}) do |memo, (k, v)|
      memo.tap { |m| m[k.to_sym] = v }
    end
  end

  def css(*stylesheets)
    stylesheets.map do |stylesheet|
      ['<link href="/', stylesheet, '.css" media="screen, projection"',
       ' rel="stylesheet" />'].join
    end.join
  end

  def set_title
    @title ||= settings.site_title
  end

  def set_sidebar_title
    @sidebar_title ||= 'Sidebar'
  end

  def nav_current?(regex = nil)
    return nil if regex.nil?
    request.path.to_s =~ regex ? 'active' : nil
  end

  def sidebar_current?(path = '/')
    request.path.to_s == path ? 'active' : nil
  end

  def authenticate!
    @user = session[:user] unless session[:user].nil?
    unless user?
      flash[:error] = 'You need to be logged in!'
      session[:return_to] = request.path_info
      redirect '/login'
    end
  end

  def user?
    @user != nil
  end

  # @param str [String]
  # @return [Boolean]
  def string_to_bool(str)
    return true if str =~ %r{^(true|yes|TRUE|YES|y|1|on|ON)$}
    return false if str =~ %r{^(false|no|FALSE|NO|n|0|off|OFF)$}
    raise ArgumentError
  end
end
