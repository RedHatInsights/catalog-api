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
          # The request was made in submit_order API. Switch to the context of the item which contains the tracking ID.
          Insights::API::Common::Request.with_request(@item.context.transform_keys(&:to_sym)) do
            validate_surveys
            send_request_to_compute_applied_inventories

            @item.update_message(:info, "Waiting for inventories")
          end
          self
        rescue
          @order.update(:state => "Failed")
          raise
        end

        private

        def send_request_to_compute_applied_inventories
          service_plan = TopologicalInventoryApiClient::AppliedInventoriesParametersServicePlan.new(
            :service_parameters => @item.service_parameters
          )
          TopologicalInventory::Service.call do |api|
            task_id = api.applied_inventories_for_service_offering(service_offering_ref, service_plan).task_id

            @item.update(:topology_task_ref => task_id)
            Rails.logger.info("OrderItem #{@item.id} updated with topology task ref #{task_id}")
          end
        end

        def service_offering_ref
          @item.portfolio_item.service_offering_ref.to_s
        end

        def validate_surveys
          changed_surveys = ::Catalog::SurveyCompare.collect_changed(@item.portfolio_item.service_plans)

          unless changed_surveys.empty?
            invalid_survey_messages = changed_surveys.collect(&:invalid_survey_message)
            raise ::Catalog::InvalidSurvey, invalid_survey_messages
          end
        end
      end
    end
  end
end
