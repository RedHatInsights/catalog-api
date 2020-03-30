module Api
  module V1x0
    module Catalog
      class CreateRequestForAppliedInventories
        attr_reader :order

        def initialize(order)
          @order = order
          @item = @order.order_items.first
        end

        def process
          raise Catalog::InvalidSurvey, "Base survey does not match Topology" if Catalog::SurveyCompare.any_changed?(@item.portfolio_item.service_plans)

          send_request_to_compute_applied_inventories

          @item.update_message(:info, "Waiting for inventories")
          self
        end

        private

        def send_request_to_compute_applied_inventories
          service_plan = TopologicalInventoryApiClient::AppliedInventoriesParametersServicePlan.new(
            :service_parameters => @item.service_parameters
          )
          TopologicalInventory.call do |api|
            task_id = api.applied_inventories_for_service_offering(service_offering_ref, service_plan).task_id

            @item.update(:topology_task_ref => task_id)
          end
        end

        def service_offering_ref
          @item.portfolio_item.service_offering_ref.to_s
        end
      end
    end
  end
end
