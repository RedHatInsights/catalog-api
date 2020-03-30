module Api
  module V1x0
    module Catalog
      class SubmitOrder
        include SourceMixin

        attr_reader :order

        def initialize(order_id)
          @order_id = order_id
        end

        def process
          @order = Order.find_by!(:id => @order_id)
          @order.order_items.each do |order_item|
            raise Catalog::NotAuthorized unless valid_source?(order_item.portfolio_item.service_offering_source_ref)

            if Catalog::SurveyCompare.any_changed?(order_item.portfolio_item.service_plans)
              order_item.mark_failed("Order Item Failed: Base survey does not match Topology")
              raise Catalog::InvalidSurvey, "Base survey does not match Topology"
            end

            submit_order_item(order_item)

            Rails.logger.info("Order #{@order_id} submitted for provisioning")
          end
          @order.update(:state => 'Ordered', :order_request_sent_at => Time.now.utc)
          @order.reload
          self
        rescue StandardError => e
          Rails.logger.error("Error Submitting Order #{@order_id}: #{e.message}")
          raise
        end

        private

        def submit_order_item(item)
          TopologicalInventory.call do |api_instance|
            result = api_instance.order_service_offering(item.portfolio_item.service_offering_ref, parameters(item))
            item.mark_ordered("Ordered", :topology_task_ref => result.task_id)
          end
        end

        def parameters(item)
          TopologicalInventoryApiClient::OrderParametersServiceOffering.new.tap do |obj|
            obj.service_parameters = sanitized_parameters(item)
            obj.provider_control_parameters = item.provider_control_parameters
            obj.service_plan_id = item.service_plan_ref
          end
        end

        def sanitized_parameters(item)
          Catalog::OrderItemSanitizedParameters.new(
            :order_item         => item,
            :do_not_mask_values => true
          ).process.sanitized_parameters
        end
      end
    end
  end
end
