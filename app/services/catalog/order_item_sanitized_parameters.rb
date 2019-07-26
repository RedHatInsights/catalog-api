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
      svc_params = ActiveSupport::HashWithIndifferentAccess.new(service_parameters)
      if service_plan_schema[:properties].present?
        service_plan_schema[:properties].each_with_object({}) do |(key, attrs), result|
          value = hide?(key, attrs) ? MASKED_VALUE : svc_params[key]
          result[attrs[:title]] = value
        end
      else
        service_plan_schema[:schema][:fields].each_with_object({}) do |(field), result|
          value = hide_ansible?(field) ? MASKED_VALUE : svc_params[field[:name]]
          result[field[:name]] = value
        end
      end
    end

    def hide_ansible?(field)
      FILTERED_PARAMS.reduce(field[:type] == "password") do |result, param|
        result || /#{param}/i.match?(field[:name]) || /#{param}/i.match?(field[:label])
      end
    end

    def hide?(key, attrs)
      FILTERED_PARAMS.reduce(attrs[:format] == "password") do |result, param|
        result || /#{param}/i.match?(attrs[:title]) || /#{param}/i.match(key)
      end
    end
  end
end
