# frozen_string_literal: true
# Helper class for the MailAccount model
# rubocop:disable Metrics/ClassLength
class MailAccount
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def initialize(params = {})
    @id = params.fetch(:id, 0)
    @email = params.fetch(:email, '')
    @realname = params.fetch(:realname, '')
    @quota = params.fetch(:quota, 10_485_760)
    @quota_sieve_script = params.fetch(:quota_sieve_script, 10_240)
    @quota_sieve_actions = params.fetch(:quota_sieve_actions, 32)
    @quota_sieve_redirects = params.fetch(:quota_sieve_redirects, 4)
    @receiving_enabled = params.fetch(:receiving_enabled, false)
    @created_at = params.fetch(:created_at, Time.now.to_i)
    @updated_at = params.fetch(:updated_at, Time.now.to_i)
    @enabled = params.fetch(:enabled, false)
    @domain_opts = {}
    @mail_alias_opts = {}
    @mail_source_opts = {}
  end

  attr_accessor :id, :email, :realname, :quota, :quota_sieve_script,
                :quota_sieve_actions, :quota_sieve_redirects,
                :receiving_enabled, :created_at, :updated_at, :enabled,
                :domain_opts, :mail_alias_opts, :mail_source_opts

  # @return [FormFieldSet]
  def field_set
    visible = []
    visible.push(email_field)
    visible.push(realname_field)
    visible.push(password_field)
    visible.push(password_field('Confirm ', 2))
    visible.push(quota_field)
    visible.push(quota_sieve_script_field)
    visible.push(quota_sieve_actions_field)
    visible.push(quota_sieve_redirects_field)
    visible.push(receiving_enabled_field)
    visible.push(enabled_field)
    visible.push(domain_field)
    visible.push(mail_alias_field)
    visible.push(mail_source_field)

    FormFieldSet.new(hidden_fields: [], visible_fields: visible).to_hash
  end

  private

  def email_field
    FormField::Text.new(
      label: 'Email Address', name: 'localpart', value: @email.split('@')[0],
      placeholder: 'f.surname'
    ).to_hash
  end

  def realname_field
    FormField::Text.new(
      label: 'Realname', name: 'realname', value: @realname,
      placeholder: 'Forename Surname'
    ).to_hash
  end

  def password_field(prefix = '', suffix = '')
    FormField::Password.new(
      label: "#{prefix}Password", name: "password#{suffix}"
    ).to_hash
  end

  def enabled_field
    FormField::Checkbox.new(
      label: 'Enable MailAccount', name: 'enabled', value: @enabled
    ).to_hash
  end

  def domain_field
    FormField::Select.new(
      label: 'Domain', name: 'domain_id', options: @domain_opts
    ).to_hash
  end

  def mail_alias_field
    FormField::SelectMultiple.new(
      label: 'Aliases', name: 'aliases', options: @mail_alias_opts
    ).to_hash
  end

  def mail_source_field
    FormField::SelectMultiple.new(
      label: 'Sources', name: 'sources', options: @mail_source_opts
    ).to_hash
  end

  def quota_field
    FormField::Text.new(
      label: 'Quota', name: 'quota', value: @quota
    ).to_hash
  end

  def quota_sieve_script_field
    FormField::Text.new(
      label: 'Sieve Script Quota',
      name: 'quota_sieve_script',
      value: @quota_sieve_script
    ).to_hash
  end

  def quota_sieve_actions_field
    FormField::Text.new(
      label: 'Sieve Actions Quota',
      name: 'quota_sieve_actions',
      value: @quota_sieve_actions
    ).to_hash
  end

  def quota_sieve_redirects_field
    FormField::Text.new(
      label: 'Sieve Redirects Quota',
      name: 'quota_sieve_redirects',
      value: @quota_sieve_redirects
    ).to_hash
  end

  def receiving_enabled_field
    FormField::Checkbox.new(
      label: 'Enable Receiving',
      name: 'receiving_enabled',
      value: @receiving_enabled
    ).to_hash
  end
end
