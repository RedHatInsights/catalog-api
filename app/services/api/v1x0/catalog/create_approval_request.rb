module Api
  module V1x0
    module Catalog
      class CreateApprovalRequest
        attr_reader :order

        def initialize(task)
          @task = task
          @order = OrderItem.find_by!(:topology_task_ref => task.id).order
        end

        def process
          @order.order_items.each do |order_item|
            submit_approval_requests(order_item)
          end

          @order.update(:state => "Approval Pending", :order_request_sent_at => Time.now.utc)
          self
        rescue ::Catalog::ApprovalError => e
          @order.order_items.first.mark_failed("Error while creating approval request")
          Rails.logger.error("Error putting in approval Request for #{order.id}: #{e.message}")
          raise
        end

        private

        def submit_approval_requests(order_item)
          response = Approval::Service.call(ApprovalApiClient::RequestApi) do |api|
            api.create_request(Api::V1x0::Catalog::CreateRequestBodyFrom.new(@order, order_item, @task).process.result)
          end

          order_item.approval_requests.create!(
            :approval_request_ref => response.id,
            :state                => response.decision.to_sym,
            :tenant_id            => order_item.tenant_id
          )

          Rails.logger.info("Approval Requests Submitted for Order #{@order.id}")
        end
      end
    end
  end
end
