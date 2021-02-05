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
            # send_request_to_compute_applied_inventories
            tag_resources = ::Tags::CollectTagResources.new(@item).process.tag_resources

            @order.update_message(:info, "Computed Tags")
            Rails.logger.info("Evaluating order processes for order item id #{@item.id}")
            # TODO: Task the first argument is nil, why do we need it here
            ::Catalog::EvaluateOrderProcess.new(nil, @item.order, tag_resources).process

            Rails.logger.info("Creating approval request for order_item id #{@item.id}")
            # TODO: Task can ve nil if we are passing in the order_item
            #       Task is then passed into CreateRequestBodyFrom which just sets an instance
            #       variable and then doesn't use it
            ::Catalog::CreateApprovalRequest.new(nil, tag_resources, @item).process
          end

          self
        rescue => e
          @order.mark_failed("Error computing inventories: #{e.message}")
          raise
        end

        private

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
