module Catalog
  class OrderItemSanitizedParameters
    attr_reader :sanitized_parameters

    MASKED_VALUE = "$protected$".freeze
    FILTERED_PARAMS = %w[password token secret].freeze

    def initialize(order_item)
      @order_item = order_item
    end

    def process
      @sanitized_parameters = compute_sanitized_parameters
      self
    rescue => e
      Rails.logger.error("OrderItemSanitizedParameters #{e.message}")
      raise
    end

    private

    def compute_sanitized_parameters
      return {} unless @order_item.service_plan_ref

      svc_params = ActiveSupport::HashWithIndifferentAccess.new(Hash(@order_item.service_parameters))
      fields.each_with_object({}) do |field, result|
        value = mask_value?(field) ? MASKED_VALUE : svc_params[field[:name]]
        result[field[:name]] = value
      end
    end

    def mask_value?(field)
      FILTERED_PARAMS.reduce(field[:type] == "password") do |result, param|
        result || /#{param}/i.match?(field[:name]) || /#{param}/i.match?(field[:label])
      end
    end

    def fields
      @fields ||= ServicePlanFields.new(@order_item).process.fields
    end
  end
end
