# frozen_string_literal: true

# Helper class for the MailForwarding model
class MailForwarding
  def initialize(params = {})
    @id = params.fetch(:id, 0)
    @address = params.fetch(:address, '')
    @destinations = params.fetch(:destinations, '')
    @created_at = params.fetch(:created_at, Time.now.to_i)
    @updated_at = params.fetch(:updated_at, Time.now.to_i)
    @enabled = params.fetch(:enabled, false)
    @domain_opts = {}
  end

  attr_accessor :id, :address, :destinations, :created_at, :updated_at,
                :enabled, :domain_opts

  # @return [FormFieldSet]
  def field_set
    visible = []
    visible.push(address_field)
    visible.push(destinations_field)
    visible.push(enabled_field)
    visible.push(domain_field)

    FormFieldSet.new(hidden_fields: [], visible_fields: visible).to_hash
  end

  private

  def address_field
    FormField::Text.new(
      label: 'Email Address', name: 'localpart', value: @address.split('@')[0],
      placeholder: ''
    ).to_hash
  end

  def destinations_field
    FormField::TextArea.new(
      label: 'Destinations', name: 'destinations', value: @destinations,
      placeholder: ''
    ).to_hash
  end

  def enabled_field
    FormField::Checkbox.new(
      label: 'Enable MailForwarding', name: 'enabled', value: @enabled
    ).to_hash
  end

  def domain_field
    FormField::Select.new(
      label: 'Domain', name: 'domain_id', options: @domain_opts
    ).to_hash
  end
end
