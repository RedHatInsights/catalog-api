module Api
  module V1x1
    module Catalog
      class ServicePlanReset < Api::V1x0::Catalog::ServicePlanReset
        attr_reader :reimported_service_plan

        private

        def reimport_from_topo
          @reimported_service_plan = Catalog::ImportServicePlans.new(@plan.portfolio_item_id, :force_reset => true).process.json
        end
      end
    end
  end
end
