class KafkaListener
  attr_accessor :messaging_client_options, :service_name, :group_ref

  def initialize(messaging_client_options, service_name, group_ref)
    self.messaging_client_options = default_messaging_options.merge(messaging_client_options)
    self.service_name = service_name
    self.group_ref = group_ref
  end

  def run
    Thread.new { subscribe }
  end

  def subscribe
    ManageIQ::Messaging::Client.open(messaging_client_options) do |client|
      client.subscribe_topic(
        :service     => service_name,
        :persist_ref => group_ref,
        :max_bytes   => 500_000
      ) do |event|
        process_event(event)
      end
    end
  rescue Kafka::ConnectionError => e
    Rails.logger.error("Cannot connect to Kafka cluster #{messaging_client_options[:host]}")
    unless messaging_client_options[:host] == 'localhost'
      sleep 30 # Remote Kafka may be down. Try again later
      retry
    end
  rescue => e
    Rails.logger.error(["Something is wrong with Kafka client: ", e.message, *e.backtrace].join($RS))
    retry
  end

  private

  def default_messaging_options
    {:protocol => :Kafka, :encoding => 'json'}
  end
end
