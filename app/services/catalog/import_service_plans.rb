module Catalog
  class ImportServicePlans
    attr_reader :service_plans

    def initialize(portfolio_item_id)
      @portfolio_item = PortfolioItem.find(portfolio_item_id)
    end

    def process
      service_plan_schemas.each do |schema|
        ServicePlan.create!(
          :base              => schema["create_json_schema"],
          :modified          => schema["create_json_schema"],
          :portfolio_item_id => @portfolio_item.id
        )
      end

      @service_plans = @portfolio_item.service_plans

      self
    end

    def service_plan_schemas
      Catalog::ServicePlans.new(@portfolio_item.id).process.items
    end
  end
end
