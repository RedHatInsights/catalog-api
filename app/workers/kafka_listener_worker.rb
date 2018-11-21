require 'manageiq-messaging'

class KafkaListenerWorker
  include Sidekiq::Worker
  TOPIC = 'Generic_Topic'.freeze
  def initialize(options = {})
    @client_ref = options.fetch(:client_ref, 'generic_1')
  end

  def start
    Thread.new { self.class.perform_async(@client_ref) }
  end

  def self.perform_async(client_ref)
    client = ManageIQ::Messaging::Client.open(
      :protocol   => 'Kafka',
      :host       => ENV['INSIGHTS_KAFKA_HOST'] || 'localhost',
      :port       => ENV['INSIGHTS_KAFKA_PORT'] || 9092,
      :client_ref => client_ref,
      :encoding   => 'json'
    )
    client.subscribe_topic(:service => self::TOPIC) { |msg| self.process(msg) }
  end
end
