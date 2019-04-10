module Catalog
  class UpdateOrderItem
    class ServiceInstanceWithoutExternalUrl < StandardError; end

    def initialize(topic)
      @payload = topic.payload
      @message = topic.message
    end

    def process
      Rails.logger.info("Processing service order topic message: #{@message} with payload: #{@payload}")

      Rails.logger.info("Searching for OrderItem with a task_ref: #{@payload["task_id"]}")
      order_item = find_order_item
      Rails.logger.info("Found OrderItem: #{order_item.id}")

      ManageIQ::API::Common::Request.with_request(order_item.context.transform_keys(&:to_sym)) do
        order_item.update_message("info", "Task update message received with payload: #{@payload}")

        if @payload["state"] == "completed"
          order_item.state = "Order Completed"
          order_item.update_message("info", "Order Complete")

          order_item.external_url = fetch_external_url

          Rails.logger.info("Updating OrderItem: #{order_item.id} with 'Order Completed' state and #{order_item.external_url}")
          order_item.save!
          Rails.logger.info("Finished updating OrderItem: #{order_item.id} with 'Order Completed' state")
        end
      end
    end

    private

    def find_order_item
      OrderItem.find_by!(:topology_task_ref => @payload["task_id"])
    rescue ActiveRecord::RecordNotFound
      Rails.logger.error("Could not find an OrderItem with topology_task_ref: #{@payload["task_id"]}")
      raise "Could not find an OrderItem with topology_task_ref: #{@payload["task_id"]}"
    end

    def fetch_external_url
      TopologicalInventory.call do |api_instance|
        task = api_instance.show_task(@payload["task_id"])
        @service_instance_id = JSON.parse(task.context)["service_instance"]["id"]
        service_instance = api_instance.show_service_instance(@service_instance_id)
        raise ServiceInstanceWithoutExternalUrl if service_instance.external_url.nil?
        service_instance.external_url
      end
    rescue ServiceInstanceWithoutExternalUrl
      Rails.logger.error("Could not find an external url on service instance (id: #{@service_instance_id}) attached to task_id: #{@payload["task_id"]}")
      raise "Could not find an external url on service instance (id: #{@service_instance_id}) attached to task_id: #{@payload["task_id"]}"
    end
  end
end
