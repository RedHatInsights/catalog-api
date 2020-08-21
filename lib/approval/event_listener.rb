module Approval
  class EventListener < KafkaListener
    SERVICE_NAME = "platform.approval".freeze
    GROUP_REF = "catalog-api-approval-minion".freeze # backward compatible
    EVENT_WORKFLOW_DELETED = 'workflow_deleted'.freeze

    def initialize(messaging_client_option)
      super(messaging_client_option, SERVICE_NAME, GROUP_REF)
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
      insights_headers = event.headers.slice('x-rh-identity', 'x-rh-insights-request-id')
      Insights::API::Common::Request.with_request(:headers => insights_headers, :original_url => nil) do |req|
        ActsAsTenant.with_tenant(Tenant.find_by!(:external_tenant => req.tenant)) do
          workflow_id = event.payload['workflow_id']
          Tag.find_by(:name => 'workflows', :namespace => 'approval', :value => workflow_id.to_s)&.destroy
        end
      end
    end

    def update_approval_status(event)
      Api::V1x0::Catalog::NotifyApprovalRequest.new(event.payload['request_id'], event.payload, event.message).process
    end
  end
end
