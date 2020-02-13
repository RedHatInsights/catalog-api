module Catalog
  class OrderItemSanitizedParameters
    attr_reader :sanitized_parameters

    MASKED_VALUE = "$protected$".freeze
    FILTERED_PARAMS = %w[password token secret].freeze

    def initialize(params)
      @params = params
      @order_item = params[:order_item]
    end

    def process
      @sanitized_parameters = compute_sanitized_parameters

      self
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

    def service_parameters_raw
      order_item.service_parameters_raw
    end

    def filtered_parameters
      service_parameters_raw.slice(*fields.collect { |field| field.with_indifferent_access["name"] })
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

    def compute_sanitized_parameters
      return {} if service_plan_does_not_exist?
      return filtered_parameters if @params[:do_not_mask_values]

      svc_params = ActiveSupport::HashWithIndifferentAccess.new(service_parameters_raw)
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

    def service_plan_does_not_exist?
      service_plan_ref.nil?
    end
  end
end
