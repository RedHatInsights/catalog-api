module Catalog
  class SubmitOrder
    attr_reader :order

    def initialize(order_id)
      @order_id = order_id
    end

    def process
      @order = Order.find_by!(:id => @order_id)
      @order.order_items.each do |order_item|
        submit_order_item(order_item)
      end
      @order.update(:state => 'Ordered', :ordered_at => Time.now.utc)
      @order.reload
      self
    rescue StandardError => e
      Rails.logger.error("Submit Order #{e.message}")
      raise
    end

    private

    def submit_order_item(item)
      TopologicalInventory.call do |api_instance|
        result = api_instance.order_service_plan(item.service_plan_ref, parameters(item))
        update_item(item, result)
      end
    end

    def parameters(item)
      TopologicalInventoryApiClient::OrderParameters.new.tap do |obj|
        obj.service_parameters = item.service_parameters
        obj.provider_control_parameters = item.provider_control_parameters
      end
    end

    def update_item(item, result)
      item.topology_task_ref = result.task_id
      item.state             = 'Ordered'
      item.ordered_at        = Time.now.utc
      item.update_message('info', 'Initialized')
      item.save!
    end
  end
end
