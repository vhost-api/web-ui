# frozen_string_literal: true
# Helper class for a html form field
class FormField
  # select field
  class Select
    def initialize(label: 'Select', name: 'select', options: [])
      @label = label
      @name = name
      @options = options
    end

    def to_hash
      { label: @label, name: @name, type: 'select', options: @options }
    end
  end

  # select multiple field
  class SelectMultiple
    def initialize(label: 'Select Multiple', name: 'select_multi', options: [])
      @label = label
      @name = name
      @options = options
    end

    def to_hash
      {
        label: @label,
        name: @name,
        type: 'select',
        options: @options,
        multiple: true
      }
    end
  end

  # checkbox field
  class Checkbox
    def initialize(label: 'Checkbox', name: 'checkbox', value: false)
      @label = label
      @name = name
      @value = value
    end

    def to_hash
      hash = { label: @label, name: @name, type: 'checkbox' }
      hash[:checked] = 'checked' if @value
      hash
    end
  end

  # password field
  class Password
    def initialize(label: 'Password', name: 'password')
      @label = label
      @name = name
    end

    def to_hash
      { label: @label, name: @name, type: 'password', placeholder: 'Password' }
    end
  end

  # text field
  class Text
    def initialize(label: 'Text', name: 'text', value: '')
      @label = label
      @name = name
      @value = value
    end

    def to_hash
      { label: @label, name: @name, type: 'text', value: @value }
    end
  end
end
