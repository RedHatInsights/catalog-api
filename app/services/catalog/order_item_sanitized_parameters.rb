module Catalog
  class OrderItemSanitizedParameters < TopologyServiceApi
    MASKED_VALUE = "********".freeze

    def process
      sanitized_parameters
    rescue StandardError => e
      Rails.logger.error("OrderItemSanitizedParameters #{e.message}")
      raise
    end

    private

    def order_item
      @order_item ||= OrderItem.find(params[:order_item_id])
    end

    def service_plan_ref
      order_item.service_plan_ref
    end

    def service_parameters
      order_item.service_parameters
    end

    def service_plan_schema
      plan = api_instance.show_service_plan(service_plan_ref)
      plan.create_json_schema
    rescue TopologicalInventoryApiClient::ApiError => e
      Rails.logger.error("DefaultApi->show_service_plan #{e.message}")
      raise
    end

    def sanitized_parameters
      svc_params = ActiveSupport::HashWithIndifferentAccess.new(service_parameters)
      service_plan_schema[:properties].each_with_object({}) do |(key, attrs), result|
        value = hide?(key, attrs) ? MASKED_VALUE : svc_params[key]
        result[attrs[:title]] = value
      end
    end

    def hide?(key, attrs)
      attrs[:format] == "password" ||
        /password/i.match?(attrs[:title]) ||
        /password/i.match?(key)
    end
  end
end
