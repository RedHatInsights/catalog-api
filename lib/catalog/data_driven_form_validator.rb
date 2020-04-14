module Catalog
  class DataDrivenFormValidator
    COMPONENTS = %i[checkbox
                    date-picker
                    field-array
                    plain-text
                    radio
                    select-field
                    select
                    sub-form
                    switch-field
                    switch
                    tab-item
                    tabs
                    text-field
                    textarea-field
                    textarea
                    time-picker
                    wizard].freeze

    VALIDATORS = %i[exact-length
                    max-length
                    min-items
                    min-length
                    pattern
                    required
                    url
                    exact-length-validator
                    max-length-validator
                    max-number-value
                    min-items-validator
                    min-length-validator
                    min-number-value
                    pattern-validator
                    required-validator
                    url-validator].freeze

    DATA_TYPES = %i[boolean
                    float
                    integer
                    number
                    string].freeze

    def self.valid?(ddf)
      ddf = ddf.class == Hash ? ddf.with_indifferent_access : JSON.parse(ddf).with_indifferent_access
      check_fields(ddf[:schema][:fields])

      true
    end

    class << self
      private

      def check_fields(fields)
        fields.each do |field|
          check_component(field[:component].to_sym)
          check_data_type(field[:dataType].to_sym) if field.key?(:dataType)
          check_validators(field[:validate]) if field.key?(:validate)
          check_options(fields)
        end
      end

      def check_component(schema_component)
        raise Catalog::InvalidSurvey, "Invalid Component: #{schema_component}" unless COMPONENTS.include?(schema_component)
      end

      def check_data_type(schema_data_type)
        raise Catalog::InvalidSurvey, "Invalid Data Type: #{schema_data_type}" unless DATA_TYPES.include?(schema_data_type)
      end

      def check_validators(schema_validators)
        schema_validators.map do |validator|
          next if validator.nil?
          raise Catalog::InvalidSurvey, "Invalid Validator: #{validator}" unless VALIDATORS.include?(validator[:type].to_sym)

          # validator types that require other fields in the validator
          case validator[:type]
          when "min-length-validator", "max-length-validator", "exact-length-validator", "min-length", "max-length", "exact-length"
            raise Catalog::InvalidSurvey, "Validator type #{validator[:type]} requires a `threshold` key" if validator[:threshold].nil?
          when "min-number-value", "max-number-value"
            raise Catalog::InvalidSurvey, "Validator type #{validator[:type]} requires a `value` key" if validator[:value].nil?
          end
        end
      end

      def check_options(schema_fields)
        schema_fields.map do |field|
          next unless field[:component] == "select-field" || field[:component] == "select" 

          # the options must contain label and value keys
          field[:options].each do |option|
            raise Catalog::InvalidSurvey, "Option types require `label` and `value` keys" unless option.key?(:label) && option.key?(:value)
          end
        end
      end
    end
  end
end
