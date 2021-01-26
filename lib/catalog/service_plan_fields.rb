module Catalog
  class ServicePlanFields
    attr_reader :fields

    def initialize(order_item)
      @order_item = order_item
    end

    def process
      @fields = Array(service_plan_schema.with_indifferent_access.dig(:schema, :fields))

      self
    end

    private

    def service_plan_schema
      # retrieve the schema in the order of modified, base, and live order

      service_plan = @order_item.portfolio_item.service_plans&.first
      service_plan&.modified || service_plan&.base || live_service_plan_schema
    end

    def live_service_plan_schema
      return {} unless @order_item.service_plan_ref

      CatalogInventory::Service.call(CatalogInventoryApiClient::ServicePlanApi) do |api|
        api.show_service_plan(@order_item.service_plan_ref.to_s).create_json_schema
      end
    rescue ::Catalog::InventoryError => e
      Rails.logger.error("DefaultApi->show_service_plan #{e.message}")
      raise
    end
  end
end
