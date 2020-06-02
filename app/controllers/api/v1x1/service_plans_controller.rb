require 'services/api/v1x1'

module Api
  module V1x1
    class ServicePlansController < Api::V1x0::ServicePlansController
      include Api::V1x1::Mixins::IndexMixin

      def reset
        service_plan = ServicePlan.find(params.require(:service_plan_id))
        authorize(service_plan)
        service_plan_reset = Catalog::ServicePlanReset.new(params.require(:service_plan_id)).process

        if service_plan_reset.status == :ok
          render :json => service_plan_reset.reimported_service_plan
        else
          head service_plan_reset.status
        end
      end
    end
  end
end
