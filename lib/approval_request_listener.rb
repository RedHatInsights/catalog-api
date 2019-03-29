require "manageiq-messaging"

class ApprovalRequestListener
  SERVICE_NAME = "platform.approval".freeze
  CLIENT_AND_GROUP_REF = "approval-catalog-api-worker".freeze
  EVENT_REQUEST_FINISHED = 'request_finished'.freeze

  attr_accessor :messaging_client_options, :client

  def initialize(messaging_client_options = {})
    self.messaging_client_options = default_messaging_options.merge(messaging_client_options)
  end

  def run
    Thread.new { subscribe_to_approval_updates }
  end

  def subscribe_to_approval_updates
    ManageIQ::Messaging::Client.open(messaging_client_options) do |client|
      client.subscribe_topic(
        :service     => SERVICE_NAME,
        :persist_ref => CLIENT_AND_GROUP_REF,
        :max_bytes   => 500_000
      ) do |topic|
        process_event(topic)
      end
    end
  end

  private

  def process_event(topic)
    approval = ApprovalRequest.find_by!(:approval_request_ref => topic.payload["request_id"])
    Rails.logger.info("Task update message received with payload: #{topic.payload}")
    approval.order_item.update_message("info", "Approval #{approval.id} #{topic.payload['decision']}")

    if topic.message == EVENT_REQUEST_FINISHED
      update_and_log_state(approval, topic.payload)
      Catalog::OrderItemTransition.new(approval.order_item_id).process
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("Could not find Approval Request with payload of #{topic.payload}")
  end

  def update_and_log_state(approval, payload)
    decision = payload['decision']
    reason = payload['reason']
    log_message = decision == "approved" ? "Approval Complete: #{reason}" : "Approval Denied: #{reason}"
    approval.order_item.update_message("info", log_message)
    approval.update!(:state => decision, :reason => reason)
  end

  def default_messaging_options
    {
      :protocol   => :Kafka,
      :client_ref => CLIENT_AND_GROUP_REF,
      :encoding   => 'json'
    }
  end
end
