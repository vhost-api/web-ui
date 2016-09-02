# frozen_string_literal: true
# Helper class for the MailAlias model
class MailAlias
  def initialize(params = {})
    @id = params.fetch(:id, 0)
    @address = params.fetch(:address, '')
    @created_at = params.fetch(:created_at, Time.now.to_i)
    @updated_at = params.fetch(:updated_at, Time.now.to_i)
    @enabled = params.fetch(:enabled, false)
    @domain_opts = {}
    @mail_account_opts = {}
  end

  attr_accessor :id, :address, :created_at, :updated_at, :enabled,
                :domain_opts, :mail_account_opts

  # @return [FormFieldSet]
  def field_set
    visible = []
    visible.push(address_field)
    visible.push(enabled_field)
    visible.push(domain_field)
    visible.push(mail_account_field)

    FormFieldSet.new(hidden_fields: [], visible_fields: visible).to_hash
  end

  private

  def address_field
    FormField::Text.new(
      label: 'Address', name: 'localpart',
      value: @address.split('@')[0], placeholder: ''
    ).to_hash
  end

  def enabled_field
    FormField::Checkbox.new(
      label: 'Enable MailAlias', name: 'enabled', value: @enabled
    ).to_hash
  end

  def domain_field
    FormField::Select.new(
      label: 'Domain', name: 'domain_id', options: @domain_opts
    ).to_hash
  end

  def mail_account_field
    FormField::SelectMultiple.new(
      label: 'Destinations', name: 'accounts', options: @mail_account_opts
    ).to_hash
  end
end
