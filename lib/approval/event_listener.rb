module Approval
  class EventListener < KafkaListener
    SERVICE_NAME = "platform.approval".freeze
    GROUP_REF = "catalog-api-approval-minion".freeze # backward compatible
    EVENT_WORKFLOW_DELETED = 'workflow_deleted'.freeze

    def initialize(messaging_client_option)
      super(messaging_client_option, ClowderConfig.instance["kafkaTopics"][SERVICE_NAME] || SERVICE_NAME, GROUP_REF)
    end

    private

    def process_event(event)
      if event.message == EVENT_WORKFLOW_DELETED
        remove_approval_tag(event)
      else
        update_approval_status(event)
      end
    end

    def remove_approval_tag(event)
      workflow_id = event.payload['workflow_id']
      Tag.find_by(:name => 'workflows', :namespace => 'approval', :value => workflow_id.to_s)&.destroy
    end

    def update_approval_status(event)
      Catalog::NotifyApprovalRequest.new(event.payload['request_id'], event.payload, event.message).process
    rescue
      order_item = ApprovalRequest.find_by(:approval_request_ref => event.payload['request_id'])&.order_item
      order_item&.mark_failed("Internal Error. Please contact our support team.")
    end
  end
end
