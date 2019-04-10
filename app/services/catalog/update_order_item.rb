module Catalog
  class UpdateOrderItem
    class OrderItemNotFound < StandardError; end

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

          Rails.logger.info("Updating OrderItem: #{order_item.id} with 'Order Completed' state")
          order_item.save!
          Rails.logger.info("Finished updating OrderItem: #{order_item.id} with 'Order Completed' state")
        end
      end
    end

    private

    def find_order_item
      order_item = OrderItem.where(:topology_task_ref => @payload["task_id"]).first
      raise OrderItemNotFound if order_item.nil?

      order_item
    rescue OrderItemNotFound
      Rails.logger.error("Could not find an OrderItem with topology_task_ref: #{@payload["task_id"]}")
      raise "Could not find an OrderItem with topology_task_ref: #{@payload["task_id"]}"
    end
  end
end
