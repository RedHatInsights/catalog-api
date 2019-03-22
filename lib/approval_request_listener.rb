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
    self.client = ManageIQ::Messaging::Client.open(messaging_client_options)

    client.subscribe_topic(
      :service   => SERVICE_NAME,
      :max_bytes => 500_000
    ) do |messages|
      messages.each do |msg|
        process_message(msg)
      end
    end
  ensure
    client&.close
    self.client = nil
  end

  private

  def process_message(msg)
    approval = ApprovalRequest.find_by!(:approval_request_ref => msg.payload["request_id"])
    approval.order_item.update_message("info", "Task update message received with payload: #{msg.payload}")
    if msg.message == EVENT_REQUEST_FINISHED && (msg.payload["decision"] == "approved" || msg.payload["decision"] == "denied")
      update_and_log_state(approval, msg.payload)
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("Could not find Approval Request with request_id of #{msg.payload['request_id']}")
    ProgressMessage.create!(
      :level   => "error",
      :message => "Could not find Approval Request with request_id of #{msg.payload['request_id']}"
    )
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
      :group_ref  => CLIENT_AND_GROUP_REF
    }
  end
end
