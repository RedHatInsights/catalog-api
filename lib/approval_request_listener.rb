require "manageiq-messaging"

class ApprovalRequestListener
  SERVICE_NAME = "platform.approval".freeze
  CLIENT_AND_GROUP_REF = "catalog-api-worker".freeze

  class ApprovalRequestNotFound < StandardError; end

  attr_accessor :messaging_client_options, :client

  def initialize(messaging_client_options = {})
    self.messaging_client_options = default_messaging_options.merge(messaging_client_options)
  end

  def run
    Thread.new { subscribe_to_approval_updates }
  end

  def subscribe_to_approval_updates
    self.client = ManageIQ::Messaging::Client.open(messaging_client_options)

    client.subscribe_messages(
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
    ProgressMessage.create!(
      :level   => "info",
      :message => "Task update message received with payload: #{msg.payload}"
    )
    if msg.payload["decision"] == "approved"
      approval = ApprovalRequest.find_by(:approval_request_ref => msg.payload["request_id"])
      raise ApprovalRequestNotFound if approval.nil?
      approval.status = msg.payload["reason"]
      # TODO Make ProgressMessage polymorphic to support multiple model types
      approval.update_message('info', 'Approval Complete')
      approval.save!
    end
  rescue ApprovalRequestNotFound
    ProgressMessage.create(
      :level   => "error",
      :message => "Could not find Approval Request with request_id of #{msg.payload["request_id"]}"
    )
  end

  def default_messaging_options
    {
      :protocol   => :Kafka,
      :client_ref => CLIENT_AND_GROUP_REF,
      :group_ref  => CLIENT_AND_GROUP_REF
    }
  end
end
