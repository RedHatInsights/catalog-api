module Catalog
  class DataDrivenFormValidator
    COMPONENTS = %i[text-field
                    textarea-field
                    field-array
                    select-field
                    checkbox
                    sub-form
                    radio
                    tabs
                    tab-item
                    date-picker
                    time-picker
                    wizard
                    switch-field
                    plain-text].freeze

    VALIDATORS = %i[required-validator
                    min-length-validator
                    max-length-validator
                    exact-length-validator
                    min-items-validator
                    min-number-value
                    max-number-value
                    pattern-validator
                    url-validator].freeze

    DATA_TYPES = %i[integer
                    float
                    number
                    boolean
                    string].freeze

    def self.valid?(ddf)
      ddf = ddf.class == Hash ? ddf.with_indifferent_access : JSON.parse(ddf).with_indifferent_access
      fields?(ddf[:schema][:fields])

      true
    end

    class << self
      def fields?(fields)
        fields.each do |field|
          component?(field[:component].to_sym)
          data_type?(field[:dataType].to_sym) if field.key?(:dataType)
          validators?(field[:validate]) if field.key?(:validate)
          options?(fields)
        end
      end

      def component?(schema_component)
        raise Catalog::InvalidSurvey unless COMPONENTS.include?(schema_component)
      end

      def data_type?(schema_data_type)
        raise Catalog::InvalidSurvey unless DATA_TYPES.include?(schema_data_type)
      end

      def validators?(schema_validators)
        schema_validators.map do |validator|
          next if validator.nil?
          raise Catalog::InvalidSurvey unless VALIDATORS.include?(validator[:type].to_sym)

          # validator types that require other fields in the validator
          case validator[:type]
          when "min-length-validator", "max-length-validator", "exact-length-validator"
            raise Catalog::InvalidSurvey if validator[:threshold].nil?
          when "min-number-value", "max-number-value"
            raise Catalog::InvalidSurvey if validator[:value].nil?
          end
        end
      end

      def options?(schema_fields)
        schema_fields.map do |field|
          next unless field[:component] == "select-field"

          # the options must contain label and value keys
          field[:options].each do |option|
            raise Catalog::InvalidSurvey unless option.key?(:label) && option.key?(:value)
          end
        end
      end
    end
  end
end
