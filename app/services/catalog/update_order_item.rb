module Catalog
  class UpdateOrderItem
    class ServiceInstanceWithoutExternalUrl < StandardError; end

    def initialize(topic, task)
      @payload = topic.payload
      @message = topic.message
      @task    = task
    end

    def process
      Rails.logger.info("Processing service order topic message: #{@message} with payload: #{@payload}")

      Rails.logger.info("Searching for OrderItem with a task_ref: #{@payload["task_id"]}")
      @order_item = find_order_item
      Rails.logger.info("Found OrderItem: #{@order_item.id}")

      @order_item.update_message("info", "Task update message received with payload: #{@payload}")

      mark_item_based_on_status
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
        @service_instance_id = @task.context[:service_instance][:id]
        service_instance = api_instance.show_service_instance(@service_instance_id)
        raise ServiceInstanceWithoutExternalUrl if service_instance.external_url.nil?
        service_instance.external_url
      end
    rescue ServiceInstanceWithoutExternalUrl
      Rails.logger.error("Could not find an external url on service instance (id: #{@service_instance_id}) attached to task_id: #{@payload["task_id"]}")
      nil
    end

    def mark_item_based_on_status
      case @payload["status"]
      when "ok"
        case @payload["state"]
        when "completed"
          @order_item.mark_completed("Order Item Complete", :external_url => fetch_external_url)
        when "running"
          @order_item.update_message("info", "Order Item being processed with context: #{@payload["context"]}")
        end
      when "error"
        @order_item.mark_failed("Order Item Failed", :external_url => fetch_external_url)
      else
        # Do nothing for now, only other case is "warn"
      end
    end
  end
end
