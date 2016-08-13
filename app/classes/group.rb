# frozen_string_literal: true
# Helper class for the Group model
class Group
  def initialize(params = {})
    @id = params.fetch(:id, 0)
    @name = params.fetch(:name, 'unknown')
    @created_at = params.fetch(:created_at, Time.now.to_i)
    @updated_at = params.fetch(:updated_at, Time.now.to_i)
    @enabled = params.fetch(:enabled, false)
  end

  attr_accessor :id,
                :name,
                :created_at,
                :updated_at,
                :enabled

  # @return [FormFieldSet]
  def field_set
    visible = []
    visible.push(name_field)
    visible.push(enabled_field)

    FormFieldSet.new(hidden_fields: [], visible_fields: visible).to_hash
  end

  private

  def name_field
    FormField::Text.new(
      label: 'Group Name', name: 'name', value: @name
    ).to_hash
  end

  def enabled_field
    FormField::Checkbox.new(
      label: 'Enabled', name: 'enabled', value: @enabled
    ).to_hash
  end
end
