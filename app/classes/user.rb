# frozen_string_literal: true
# Helper class for the User model
class User
  def initialize(params = {})
    @id = params.fetch(:id, 0)
    @name = params.fetch(:name, '')
    @login = params.fetch(:login, '')
    @contact_email = params.fetch(:contact_email, '')
    @created_at = params.fetch(:created_at, Time.now.to_i)
    @updated_at = params.fetch(:updated_at, Time.now.to_i)
    @enabled = params.fetch(:enabled, false)
    @group_opts = {}
    @package_opts = {}
  end

  attr_accessor :id, :name, :login, :contact_email, :created_at, :updated_at,
                :enabled, :group_opts, :package_opts

  # @return [FormFieldSet]
  def field_set
    visible = []
    visible.push(name_field,
                 login_field,
                 contact_email_field,
                 password_field,
                 password_field('Confirm ', 2),
                 enabled_field,
                 group_field,
                 package_field)

    FormFieldSet.new(hidden_fields: [], visible_fields: visible).to_hash
  end

  private

  def name_field
    FormField::Text.new(
      label: 'User Name', name: 'name', value: @name,
      placeholder: 'Max Mustermann'
    ).to_hash
  end

  def login_field
    FormField::Text.new(
      label: 'Login', name: 'login', value: @login,
      placeholder: 'm.mustermann'
    ).to_hash
  end

  def contact_email_field
    FormField::Text.new(
      label: 'Contact Email', name: 'contact_email', value: @contact_email,
      placeholder: 'max@mustermann.com'
    ).to_hash
  end

  def password_field(prefix = '', suffix = '')
    FormField::Password.new(
      label: "#{prefix}Password", name: "password#{suffix}"
    ).to_hash
  end

  def enabled_field
    FormField::Checkbox.new(
      label: 'Enabled', name: 'enabled', value: @enabled
    ).to_hash
  end

  def group_field
    FormField::Select.new(
      label: 'Group', name: 'group_id', options: @group_opts
    ).to_hash
  end

  def package_field
    FormField::SelectMultiple.new(
      label: 'Packages', name: 'packages', options: @package_opts
    ).to_hash
  end
end
