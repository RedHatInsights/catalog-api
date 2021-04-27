class KafkaListener
  attr_accessor :messaging_client_options, :service_name, :group_ref

  def initialize(messaging_client_options, service_name, group_ref)
    self.messaging_client_options = default_messaging_options.merge(messaging_client_options)
    self.service_name = service_name
    self.group_ref = group_ref

    Rails.logger.info("Kafka topics: #{service_name}")
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
        raw_process(event)
      end
    end
  rescue => e
    Rails.logger.error(["Something is wrong with Kafka client: ", e.message, *e.backtrace].join($RS))
    retry
  end

  private

  def raw_process(event)
    Rails.logger.info("Kafka message #{event.message} received with payload: #{event.payload}")

    # reconstruct runtime from message header, skip the message if it is not properly constructed
    insights_headers = event.headers.slice('x-rh-identity', 'x-rh-insights-request-id')
    unless insights_headers['x-rh-identity'] && insights_headers['x-rh-insights-request-id']
      Rails.logger.error("Message skipped because of missing required headers")
      return
    end

    Insights::API::Common::Request.with_request(:headers => insights_headers, :original_url => nil) do |req|
      ActiveRecord::Base.connection_pool.with_connection do
        tenant = Tenant.find_by(:external_tenant => req.tenant)
        if tenant
          ActsAsTenant.with_tenant(tenant) do
            process_event(event)
          end
        else
          Rails.logger.error("Message skipped because it does not belong to a valid tenant")
        end
      end
    end
  rescue => e
    Rails.logger.error("Error processing event: #{e.message}")
  ensure
    event.ack
  end

  def default_messaging_options
    {:protocol => :Kafka, :encoding => 'json'}
  end
end
