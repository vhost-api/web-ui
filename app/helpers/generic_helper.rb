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

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def set_title
    @title ||= settings.site_title
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def set_sidebar_title
    @sidebar_title ||= 'Sidebar'
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def nav_current?(regex = nil)
    return nil if regex.nil?
    request.path.to_s.match?(regex) ? 'active' : nil
  end

  def sidebar_current?(regex = nil)
    return nil if regex.nil?
    request.path.to_s.match?(regex) ? 'active' : nil
  end

  def authenticate!
    @user = session[:user] unless session[:user].nil?
    return true if user?

    flash[:error] = 'You need to be logged in!'
    session[:return_to] = request.path_info
    redirect '/login'
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

  def link_with_mtime(path)
    abs_path = settings.public_folder.chomp('/') + path
    path += '?' + File.mtime(abs_path).strftime('%s') if File.file?(abs_path)
    path
  end

  def haml_td_bool(state, &block)
    return nil unless is_haml?
    classes = ['icon']
    alt = ''
    if state
      classes.concat(['icon-active', 'item-enabled'])
      alt = 'Enabled'
    else
      classes.concat(['icon-disabled', 'item-disabled'])
      alt = 'Disabled'
    end
    haml_tag :td, class: classes, alt: alt, title: alt, &block
  end

  def haml_td_edit(base, id, name, alt)
    return nil unless is_haml?
    href = "#{base}/#{id}/edit"
    alt = "Edit #{alt}"
    haml_tag :td do
      haml_tag :a, href: href, alt: alt, title: alt do
        haml_concat name
      end
    end
  end

  def haml_td_delete(base, id, alt)
    return nil unless is_haml?
    classes = ['icon', 'item-delete', 'icon-trash']
    href = "#{base}/#{id}/delete"
    alt = "Delete #{alt}"
    haml_tag :td do
      haml_tag :a, class: classes, href: href, alt: alt, title: alt
    end
  end
end
