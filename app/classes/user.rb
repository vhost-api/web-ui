# frozen_string_literal: true
# Helper class for the User model
# rubocop:disable Metrics/ClassLength
class User
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def initialize(params = {})
    @id = params.fetch(:id, 0)
    @name = params.fetch(:name, 'Unknown')
    @login = params.fetch(:login, 'unknown')
    @contact_email = params.fetch(:contact_email, 'unknown@example.com')
    @quota_apikeys = params.fetch(:quota_apikeys, 0)
    @quota_ssh_pubkeys = params.fetch(:quota_ssh_pubkeys, 0)
    @quota_customers = params.fetch(:quota_customers, 0)
    @quota_vhosts = params.fetch(:quota_vhosts, 0)
    @quota_vhost_storage = params.fetch(:quota_vhost_storage, 0)
    @quota_databases = params.fetch(:quota_databases, 0)
    @quota_database_users = params.fetch(:quota_database_users, 0)
    @quota_dns_zones = params.fetch(:quota_dns_zones, 0)
    @quota_dns_records = params.fetch(:quota_dns_records, 0)
    @quota_domains = params.fetch(:quota_domains, 0)
    @quota_mail_accounts = params.fetch(:quota_mail_accounts, 0)
    @quota_mail_aliases = params.fetch(:quota_mail_aliases, 0)
    @quota_mail_sources = params.fetch(:quota_mail_sources, 0)
    @quota_mail_storage = params.fetch(:quota_mail_storage, 0)
    @quota_sftp_users = params.fetch(:quota_sftp_users, 0)
    @quota_shell_users = params.fetch(:quota_shell_users, 0)
    @created_at = params.fetch(:created_at, Time.now.to_i)
    @updated_at = params.fetch(:updated_at, Time.now.to_i)
    @enabled = params.fetch(:enabled, false)
    @group_opts = {}
  end

  attr_accessor :id, :name, :login, :contact_email, :created_at, :updated_at,
                :enabled, :group_opts
  attr_accessor :quota_apikeys, :quota_ssh_pubkeys, :quota_customers,
                :quota_vhosts, :quota_vhost_storage, :quota_databases,
                :quota_database_users, :quota_dns_zones, :quota_dns_records,
                :quota_domains, :quota_mail_accounts, :quota_mail_aliases,
                :quota_mail_sources, :quota_mail_storage, :quota_sftp_users,
                :quota_shell_users

  # @return [FormFieldSet]
  def field_set
    visible = []
    visible.push(name_field)
    visible.push(login_field)
    visible.push(contact_email_field)
    visible.push(password_field)
    visible.push(password_field('Confirm ', 2))

    visible.push(quota_apikeys_field)
    visible.push(quota_ssh_pubkeys_field)
    visible.push(quota_customers_field)
    visible.push(quota_vhosts_field)
    visible.push(quota_vhost_storage_field)
    visible.push(quota_databases_field)
    visible.push(quota_database_users_field)
    visible.push(quota_dns_zones_field)
    visible.push(quota_dns_records_field)
    visible.push(quota_domains_field)
    visible.push(quota_mail_accounts_field)
    visible.push(quota_mail_aliases_field)
    visible.push(quota_mail_sources_field)
    visible.push(quota_mail_storage_field)
    visible.push(quota_sftp_users_field)
    visible.push(quota_shell_users_field)

    visible.push(enabled_field)
    visible.push(group_field)

    FormFieldSet.new(hidden_fields: [], visible_fields: visible).to_hash
  end

  private

  def name_field
    FormField::Text.new(
      label: 'User Name', name: 'name', value: @name
    ).to_hash
  end

  def login_field
    FormField::Text.new(
      label: 'Login', name: 'login', value: @login
    ).to_hash
  end

  def contact_email_field
    FormField::Text.new(
      label: 'Contact Email', name: 'contact_email', value: @contact_email
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

  def quota_apikeys_field
    FormField::Text.new(
      label: 'Apikey Quota', name: 'quota_apikeys', value: @quota_apikeys
    ).to_hash
  end

  def quota_ssh_pubkeys_field
    FormField::Text.new(
      label: 'SSH Pubkey Quota',
      name: 'quota_ssh_pubkeys',
      value: @quota_ssh_pubkeys
    ).to_hash
  end

  def quota_customers_field
    FormField::Text.new(
      label: 'Customer Quota',
      name: 'quota_customers',
      value: @quota_customers
    ).to_hash
  end

  def quota_vhosts_field
    FormField::Text.new(
      label: 'Vhost Quota',
      name: 'quota_vhosts',
      value: @quota_vhosts
    ).to_hash
  end

  def quota_vhost_storage_field
    FormField::Text.new(
      label: 'Vhost Storage Quota',
      name: 'quota_vhost_storage',
      value: @quota_vhost_storage
    ).to_hash
  end

  def quota_databases_field
    FormField::Text.new(
      label: 'Database Quota',
      name: 'quota_databases',
      value: @quota_databases
    ).to_hash
  end

  def quota_database_users_field
    FormField::Text.new(
      label: 'Database Users Quota',
      name: 'quota_database_users',
      value: @quota_database_users
    ).to_hash
  end

  def quota_dns_zones_field
    FormField::Text.new(
      label: 'DNS Zones Quota',
      name: 'quota_dns_zones',
      value: @quota_dns_zones
    ).to_hash
  end

  def quota_dns_records_field
    FormField::Text.new(
      label: 'DNS Records Quota',
      name: 'quota_dns_records',
      value: @quota_dns_records
    ).to_hash
  end

  def quota_domains_field
    FormField::Text.new(
      label: 'Domain Quota',
      name: 'quota_domains',
      value: @quota_domains
    ).to_hash
  end

  def quota_mail_accounts_field
    FormField::Text.new(
      label: 'MailAccount Quota',
      name: 'quota_mail_accounts',
      value: @quota_mail_accounts
    ).to_hash
  end

  def quota_mail_aliases_field
    FormField::Text.new(
      label: 'MailAlias Quota',
      name: 'quota_mail_aliases',
      value: @quota_mail_aliases
    ).to_hash
  end

  def quota_mail_sources_field
    FormField::Text.new(
      label: 'MailSource Quota',
      name: 'quota_mail_sources',
      value: @quota_mail_sources
    ).to_hash
  end

  def quota_mail_storage_field
    FormField::Text.new(
      label: 'Mail Storage Quota',
      name: 'quota_mail_storage',
      value: @quota_mail_storage
    ).to_hash
  end

  def quota_sftp_users_field
    FormField::Text.new(
      label: 'SFTP Users Quota',
      name: 'quota_sftp_users',
      value: @quota_sftp_users
    ).to_hash
  end

  def quota_shell_users_field
    FormField::Text.new(
      label: 'Shell Users Quota',
      name: 'quota_shell_users',
      value: @quota_shell_users
    ).to_hash
  end
end
