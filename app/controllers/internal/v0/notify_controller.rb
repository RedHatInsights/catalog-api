module Internal
  module V0
    class NotifyController < ::ApplicationController
      def notify_approval_request
        request_id = params.require(:request_id)
        payload = params.require(:payload)

        ActsAsTenant.without_tenant do
          Catalog::NotifyApprovalRequest.new(request_id, payload).process
        end

        json_response(nil)
      end

      def notify_order_item
        task_id = params.require(:task_id)
        payload = params.require(:payload)
        message = params.require(:message)

        topic = Struct.new(:payload, :message).new(payload.merge("task_id" => task_id), message)
        ActsAsTenant.without_tenant do
          Catalog::UpdateOrderItem.new(topic).process
        end

        json_response(nil)
      end
    end
  end
end
