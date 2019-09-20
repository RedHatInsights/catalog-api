module Catalog
  class OrderItemSanitizedParameters
    MASKED_VALUE = "********".freeze
    FILTERED_PARAMS = %w[password token secret].freeze

    def initialize(params)
      @params = params
    end

    def process
      sanitized_parameters
    rescue StandardError => e
      Rails.logger.error("OrderItemSanitizedParameters #{e.message}")
      raise
    end

    private

    def order_item
      @order_item ||= OrderItem.find(@params[:order_item_id])
    end

    def service_plan_ref
      order_item.service_plan_ref
    end

    def service_parameters
      order_item.service_parameters
    end

    def service_plan_schema
      TopologicalInventory.call do |api|
        @plan = api.show_service_plan(service_plan_ref.to_s)
      end
      @plan.create_json_schema
    rescue TopologicalInventoryApiClient::ApiError => e
      Rails.logger.error("DefaultApi->show_service_plan #{e.message}")
      raise
    end

    def sanitized_parameters
      return {} if service_plan_ref == "DNE"

      svc_params = ActiveSupport::HashWithIndifferentAccess.new(service_parameters)
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
      service_plan_schema.dig(:schema, :fields) || []
    end
  end
end
