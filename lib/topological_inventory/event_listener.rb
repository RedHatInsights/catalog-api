module TopologicalInventory
  class EventListener < KafkaListener
    SERVICE_NAME = "platform.topological-inventory.task-output-stream".freeze
    GROUP_REF = "catalog-api-task-minion".freeze # backward compatible

    def initialize(messaging_client_option)
      super(messaging_client_option, SERVICE_NAME, GROUP_REF)
    end

    private

    def process_event(event)
      Rails.logger.info("Kafka message #{event.message} received with payload: #{event.payload}")

      event.payload['task_id'] = event.payload.delete('id')
      topic = OpenStruct.new(:payload => event.payload, :message => event.message)
      Api::V1x0::Catalog::DetermineTaskRelevancy.new(topic).process
    end
  end
end
