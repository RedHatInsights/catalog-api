module Api
  module V1x0
    module Catalog
      class ServicePlanReset
        attr_reader :status
        attr_reader :reimported_service_plan

        def initialize(service_plan_id)
          @plan = ServicePlan.find(service_plan_id)
        end

        def process
          @status = if @plan.modified.nil?
                      :no_content
                    else
                      :ok
                    end

          reimport_from_topo
          self
        rescue StandardError => e
          Rails.logger.error("Service Plans #{e.message}")
          raise
        end

        private

        def reimport_from_topo
          @reimported_service_plan = Catalog::ImportServicePlans.new(@plan.portfolio_item_id, :force_reset => true).process.json
        end
      end
    end
  end
end
