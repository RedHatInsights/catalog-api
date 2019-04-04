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
    Catalog::UpdateOrderItem.new(topic).process
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
