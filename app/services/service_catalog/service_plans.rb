module ServiceCatalog
  class ServicePlans
    attr_reader :items
    def initialize(portfolio_item_id)
      @portfolio_item_id = portfolio_item_id
    end

    def process
      result = api_instance.list_service_offering_service_plans(service_offering_ref)
      @items = filter_result(result)
      self
    rescue StandardError => e
      Rails.logger.error("Service Plans #{e.message}")
      raise
    end

    def service_offering_ref
      PortfolioItem.find(@portfolio_item_id).service_offering_ref
    end

    def filter_result(result)
      result.collect do |obj|
        {
          'name'               => obj.name,
          'description'        => obj.description,
          'id'                 => obj.id,
          'create_json_schema' => obj.create_json_schema
        }
      end
    end

    def api_instance
      @api_instance ||= TopologicalInventory.api
    end
  end
end
