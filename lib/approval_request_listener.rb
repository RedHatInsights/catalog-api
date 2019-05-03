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

    Rails.logger.info("Catalog API approval listener started...")

    ManageIQ::Messaging::Client.open(messaging_client_options) do |client|
      client.subscribe_topic(
        :service     => SERVICE_NAME,
        :persist_ref => CLIENT_AND_GROUP_REF,
        :max_bytes   => 500_000
      ) do |topic|
        Rails.logger.info("Starting process_event")
        process_event(topic)
        Rails.logger.info("Finished process_event")
      end
    end
  end

  private

  def process_event(topic)
    Rails.logger.info("Task update message #{topic.message} received with payload: #{topic.payload}")
    approval = ApprovalRequest.find_by!(:approval_request_ref => topic.payload["request_id"])
    approval.order_item.update_message("info", "Approval #{approval.id} message: #{topic.message} decision:  #{topic.payload['decision']}")

    if topic.message == EVENT_REQUEST_FINISHED
      Rails.logger.info("Starting update_and_log_state for Approval ID: #{approval.id} with payload: #{topic.payload}")
      update_and_log_state(approval, topic)
      Rails.logger.info("Finished update_and_log_state for Approval ID: #{approval.id} with payload: #{topic.payload}")
      Rails.logger.info("Staring Catalog::ApprovalTransition for order_item_id: #{approval.order_item_id}")
      Catalog::ApprovalTransition.new(approval.order_item_id).process
      Rails.logger.info("Finished Catalog::ApprovalTransition for order_item_id: #{approval.order_item_id}")
    end
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("Could not find Approval Request with payload of #{topic.payload}")
  rescue Exception => e
    Rails.logger.error("An Exception was rescued in the Approval Listener: #{e.message} Details: #{e.inspect}")
  end

  def update_and_log_state(approval, topic)
    Rails.logger.info("Inside update_and_log_state")
    decision = topic.payload['decision']
    reason = topic.payload['reason']
    message = topic.message
    log_message = decision == "approved" ? "Approval Complete: message: #{message} reason: #{reason}" : "Approval Denied: message: #{message} reason: #{reason}"
    Rails.logger.info("Built log message of: #{log_message}")
    approval.order_item.update_message("info", log_message)
    Rails.logger.info("Updated the order item message")
    approval.update!(:state => decision, :reason => reason)
    Rails.logger.info("Updated the ApprovalRequest record with state: #{decision}, and reason: #{reason}")
  end

  def default_messaging_options
    {
      :protocol   => :Kafka,
      :client_ref => CLIENT_AND_GROUP_REF,
      :encoding   => 'json'
    }
  end
end
