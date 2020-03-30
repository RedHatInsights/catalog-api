module Api
  module V1x0
    module Catalog
      class ImportServicePlans
        attr_reader :json

        def initialize(portfolio_item_id, force_reset: false)
          @portfolio_item = PortfolioItem.find(portfolio_item_id)
          force_reset ? clear_service_plans : check_conflict
        end

        def process
          service_plan_schemas.each do |schema|
            ServicePlan.create!(
              :name              => schema["name"],
              :description       => schema["description"],
              :base              => schema["create_json_schema"],
              :portfolio_item_id => @portfolio_item.id
            )
          end

          @json = Catalog::ServicePlanJson.new(:portfolio_item_id => @portfolio_item.id, :collection => true).process.json

          self
        end

        private

        def check_conflict
          raise Catalog::ConflictError, "Service Plan already exists for PortfolioItem: #{@portfolio_item.id}" if @portfolio_item.service_plans.any?
        end

        def clear_service_plans
          @portfolio_item.service_plans.destroy_all
        end

        def service_plan_schemas
          Catalog::ServicePlans.new(@portfolio_item.id).process.items
        end
      end
    end
  end
end
