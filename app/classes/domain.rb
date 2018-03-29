# frozen_string_literal: true

# Helper class for the Domain model
class Domain
  def initialize(params = {})
    @id = params.fetch(:id, 0)
    @name = params.fetch(:name, '')
    @mail_enabled = params.fetch(:mail_enabled, false)
    @dns_enabled = params.fetch(:dns_enabled, false)
    @created_at = params.fetch(:created_at, Time.now.to_i)
    @updated_at = params.fetch(:updated_at, Time.now.to_i)
    @enabled = params.fetch(:enabled, false)
    @user_opts = {}
  end

  attr_accessor :id,
                :name,
                :mail_enabled,
                :dns_enabled,
                :created_at,
                :updated_at,
                :enabled,
                :user_opts

  # @return [FormFieldSet]
  def field_set
    hidden = []
    visible = []
    visible.push(name_field)
    visible.push(mail_enabled_field)
    visible.push(dns_enabled_field)
    visible.push(enabled_field)
    visible.push(user_field)

    FormFieldSet.new(hidden_fields: hidden, visible_fields: visible).to_hash
  end

  private

  def name_field
    FormField::Text.new(
      label: 'Domain Name', name: 'name', value: @name,
      placeholder: 'Domain Name'
    ).to_hash
  end

  def mail_enabled_field
    FormField::Checkbox.new(
      label: 'Enable Email module for this domain', name: 'mail_enabled',
      value: @mail_enabled
    ).to_hash
  end

  def dns_enabled_field
    FormField::Checkbox.new(
      label: 'Enable DNS module for this domain', name: 'dns_enabled',
      value: @dns_enabled
    ).to_hash
  end

  def enabled_field
    FormField::Checkbox.new(
      label: 'Enable Domain', name: 'enabled', value: @enabled
    ).to_hash
  end

  def user_field
    FormField::Select.new(
      label: 'User', name: 'user_id', options: @user_opts
    ).to_hash
  end
end
