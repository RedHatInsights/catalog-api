module Catalog
  class UpdateOrderItem
    def initialize(topic, task, order_item = nil)
      @payload    = topic.payload
      @message    = topic.message
      @task       = task
      order_item ||= OrderItem.find_by!(:topology_task_ref => @task.id)
      @order_item = order_item
    end

    def process
      Rails.logger.info("Processing service order topic message: #{@message} with payload: #{@payload}")

      @order_item.update_message("info", "Task update message received with payload: #{@payload}")

      mark_item_based_on_status
    end

    private

    def mark_item_based_on_status
      case @payload["status"]
      when "ok"
        case @payload["state"]
        when "completed"
          @order_item.mark_completed("Order Item Complete", :service_instance_ref => service_instance_id)
        when "running"
          @order_item.update_message("info", "Order Item being processed with context: #{@payload["context"]}")
          @order_item.update!(:external_url => @task.context.dig(:service_instance, :url))
        end
      when "error"
        @order_item.mark_failed("Order Item Failed", :service_instance_ref => service_instance_id)
      end
    end

    def service_instance_id
      @service_instance_id ||= @task.context.dig(:service_instance, :id) || @order_item.service_instance_ref.to_s
    end
  end
end
