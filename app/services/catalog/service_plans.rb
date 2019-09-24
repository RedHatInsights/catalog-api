module Catalog
  class ServicePlans
    SERVICE_PLAN_DOES_NOT_EXIST = "DNE".freeze

    attr_reader :items
    def initialize(portfolio_item_id)
      @portfolio_item_id = portfolio_item_id
    end

    def process
      ref = PortfolioItem.find(@portfolio_item_id).service_offering_ref
      TopologicalInventory.call do |api_instance|
        result = api_instance.list_service_offering_service_plans(ref)
        @items = filter_result(result.data, ref)
      end
      self
    rescue StandardError => e
      Rails.logger.error("Service Plans #{e.message}")
      raise
    end

    private

    def filter_result(result, ref)
      if result.empty?
        no_service_plan(ref)
      else
        result.collect do |obj|
          {
            'name'               => obj.name,
            'description'        => obj.description,
            'id'                 => obj.id,
            'create_json_schema' => obj.create_json_schema
          }
        end
      end
    end

    def no_service_plan(ref)
      [{
        'service_offering_id' => ref,
        'description'         => "Description",
        'id'                  => SERVICE_PLAN_DOES_NOT_EXIST,
        'create_json_schema'  => {
          'type'       => 'object',
          'properties' => {}
        }
      }]
    end
  end
end
