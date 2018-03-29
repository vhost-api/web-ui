# frozen_string_literal: true

# Helper class for a html form field set
class FormFieldSet
  def initialize(hidden_fields: [], visible_fields: [])
    @hidden_fields = hidden_fields
    @visible_fields = visible_fields
  end

  def to_hash
    { hidden_fields: @hidden_fields, visible_fields: @visible_fields }
  end
end
