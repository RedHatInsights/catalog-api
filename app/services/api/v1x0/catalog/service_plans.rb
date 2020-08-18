module Api
  module V1x0
    module Catalog
      class ServicePlans
        include ::Catalog::JsonSchemaReader

        attr_reader :items

        def initialize(portfolio_item_id)
          @portfolio_item_id = portfolio_item_id
        end

        def process
          @reference = PortfolioItem.find(@portfolio_item_id).service_offering_ref
          @imported = false
          @modified = false

          TopologicalInventory::Service.call do |api_instance|
            service_offering = api_instance.show_service_offering(@reference)

            if service_offering.extra[:survey_enabled]
              result = api_instance.list_service_offering_service_plans(@reference)
              @items = filter_data(result.data)
            else
              @items = filter_data
            end
          end

          self
        rescue StandardError => e
          Rails.logger.error("Service Plans #{e.message}")
          raise
        end

        private

        def filter_data(data = [])
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
  end
end
