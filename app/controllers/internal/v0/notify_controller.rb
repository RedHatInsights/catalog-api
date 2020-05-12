module Internal
  module V0
    class NotifyController < ::ApplicationController
      skip_before_action :validate_primary_collection_id
      self.openapi_enabled = false

      def notify_approval_request
        request_id = params.require(:request_id)
        payload = params.require(:payload)
        message = params.require(:message)

        ActsAsTenant.without_tenant do
          Api::V1x0::Catalog::NotifyApprovalRequest.new(request_id, payload, message).process
        end
        json_response(nil)
      end

      def notify_task
        Rails.logger.info("#notify_task incoming parameters: #{params}")
        task_id = params.require(:task_id)
        payload = params.require(:payload).permit!.to_h
        message = params.require(:message)

        Rails.logger.info("Notification about task id: #{task_id}, payload: #{payload}, message: #{message}")

        topic = OpenStruct.new(:payload => payload.merge("task_id" => task_id), :message => message)
        ActsAsTenant.without_tenant do
          Api::V1x0::Catalog::DetermineTaskRelevancy.new(topic).process
        end

        json_response(nil)
      end
    end
  end
end
