require 'manageiq-messaging'

class KafkaListenerWorker
  include Sidekiq::Worker

  def initialize(topic)
    @topic = topic
    @portal_ref = 'generic_1'
  end

  def start
    Thread.new { KafkaListenerWorker.perform_async(@topic, @ref) }
  end

  def self.perform_async(topic, client_ref)
    client = ManageIQ::Messaging::Client.open(
      :protocol   => 'Kafka',
      :host       => ENV['INSIGHTS_KAFKA_HOST'] || 'localhost',
      :port       => ENV['INSIGHTS_KAFKA_PORT'] || 9092,
      :client_ref => client_ref,
      :encoding   => 'json'
    )
    client.subscribe_topic(:service => topic) do |_, _, message|
      File.open("/tmp/#{topic}.log", "a") do |f|
        f.write("#{Time.now} => #{message}\n")
      end
    end
  end
end
