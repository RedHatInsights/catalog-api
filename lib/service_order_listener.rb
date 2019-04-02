require "manageiq-messaging"

class ServiceOrderListener
  SERVICE_NAME = "platform.topological-inventory.task-output-stream".freeze
  CLIENT_REF = "catalog-api-worker".freeze

  class OrderItemNotFound < StandardError; end

  attr_accessor :messaging_client_options, :client

  def initialize(messaging_client_options = {})
    self.messaging_client_options = default_messaging_options.merge(messaging_client_options)
  end

  def run
    Thread.new { subscribe_to_task_updates }
  end

  def subscribe_to_task_updates
    Rails.logger.info("Catalog API service order listener started...")

    ManageIQ::Messaging::Client.open(messaging_client_options) do |client|
      client.subscribe_topic(
        :service     => SERVICE_NAME,
        :persist_ref => CLIENT_REF,
        :max_bytes   => 500_000
      ) do |topic|
        process_event(topic)
      end
    end
  end

  private

  def process_event(topic)
    Rails.logger.info("Processing service order topic message: #{topic.message} with payload: #{topic.payload}")

    ProgressMessage.create!(
      :level   => "info",
      :message => "Task update message received with payload: #{topic.payload}"
    )

    if topic.payload["state"] == "completed"
      Rails.logger.info("Searching for OrderItem with a task_ref: #{topic.payload["task_id"]}")
      item = OrderItem.where(:topology_task_ref => topic.payload["task_id"]).first
      raise OrderItemNotFound if item.nil?

      Rails.logger.info("Found OrderItem: #{item.id}")
      item.state = 'Order Completed'
      item.update_message('info', 'Order Complete')

      Rails.logger.info("Updating OrderItem: #{item.id} with 'Order Completed' state")
      item.save!
      Rails.logger.info("Finished updating OrderItem: #{item.id} with 'Order Completed' state")
    end
  rescue OrderItemNotFound
    Rails.logger.error("Could not find an OrderItem with topology_task_ref: #{topic.payload["task_id"]}")
    ProgressMessage.create(
      :level   => "error",
      :message => "Could not find OrderItem with topology_task_ref of #{topic.payload["task_id"]}"
    )
  rescue Exception => e
    Rails.logger.error("An Exception was rescued in the Service Order Listener: #{e.message} Details: #{e.inspect}")
  end

  def default_messaging_options
    {
      :protocol   => :Kafka,
      :client_ref => CLIENT_REF,
      :encoding   => "json"
    }
  end
end
