module Catalog
  class ServicePlans
    include Catalog::JsonSchemaReader

    attr_reader :items

    def initialize(portfolio_item_id)
      @portfolio_item_id = portfolio_item_id
    end

    def process
      @reference = PortfolioItem.find(@portfolio_item_id).service_offering_ref

      TopologicalInventory.call do |api_instance|
        result = api_instance.list_service_offering_service_plans(@reference)
        @items = filter_data(result.data)
      end

      self
    rescue StandardError => e
      Rails.logger.error("Service Plans #{e.message}")
      raise
    end

    private

    def filter_data(data)
      if data.empty?
        [read_json_schema("no_service_plan.erb")]
      else
        data.collect do |service_plan|
          @service_plan = service_plan
          read_json_schema("service_plan.erb")
        end
      end
    end
  end
end
