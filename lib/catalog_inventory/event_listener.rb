module CatalogInventory
  class EventListener < KafkaListener
    SERVICE_NAME = "platform.catalog-inventory.task-output-stream".freeze
    GROUP_REF = "catalog-api-task-minion".freeze # backward compatible

    def initialize(messaging_client_option)
      super(messaging_client_option, SERVICE_NAME, GROUP_REF)
    end

    private

    def process_event(event)
      event.payload['task_id'] = event.payload.delete('id')
      topic = OpenStruct.new(:payload => event.payload, :message => event.message)
      Catalog::DetermineTaskRelevancy.new(topic).process
    rescue
      order_item = OrderItem.find_by(:topology_task_ref => event.payload['task_id'].to_s)
      order_item&.mark_failed("Internal Error. Please contact our support team.")
    end
  end
end
