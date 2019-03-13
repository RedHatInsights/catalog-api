require "manageiq-messaging"

class ServiceOrderListener
  SERVICE_NAME = "platform.topological-inventory.task-output-stream".freeze
  CLIENT_AND_GROUP_REF = "catalog-api-worker".freeze

  class OrderItemNotFound < StandardError; end

  attr_accessor :messaging_client_options, :client

  def initialize(messaging_client_options = {})
    self.messaging_client_options = default_messaging_options.merge(messaging_client_options)
  end

  def run
    Thread.new { subscribe_to_task_updates }
  end

  def subscribe_to_task_updates
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

    if msg.payload["state"] == "completed"
      item = OrderItem.where(:topology_task_ref => msg.payload["task_id"]).first
      raise OrderItemNotFound if item.nil?
      item.state = 'Order Completed'
      item.update_message('info', 'Order Complete')
      item.save!
    end
  rescue OrderItemNotFound
    ProgressMessage.create(
      :level   => "error",
      :message => "Could not find OrderItem with topology_task_ref of #{msg.payload["task_id"]}"
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
