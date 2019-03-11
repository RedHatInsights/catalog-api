class ServiceOrderListener
  attr_accessor :messaging_client_options, :client

  def initialize(messaging_client_options = {})
    self.messaging_client_options = default_messaing_options.merge(messaging_client_options)
  end

  def run
    Thread.new do
      self.client = ManageIQ::Messaging::Client.open(messaging_client_options)

      client.subscribe_messages({
        :service   => "platform.topological-inventory.task-output-stream",
        :max_bytes => 500_000
      }) do |messages|
        messages.each do |msg|
          process_message(msg)
        end
      end
    end
  ensure
    client&.close
    self.client = nil
  end

  private

  def process_message(msg)
    if msg.payload["state"] == "completed"
      item = OrderItem.where(:topology_task_ref => msg.payload["task_id"]).first
      item.state = 'Order Completed?'
      item.update_message('info', 'Order Complete')
      item.save!
    end
  end

  def default_messaing_options
    {
      :protocol   => :Kafka,
      :client_ref => "catalog-api-worker?",
      :group_ref  => "catalog-api-worker?"
    }
  end
end
