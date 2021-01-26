module Catalog
  class OrderStateTransition
    attr_reader :state

    def initialize(order)
      @order = order
    end

    # This is service is called only when the order has been approved
    def process
      update_order_state
      @state = @order.state

      self
    end

    private

    def update_order_state
      item_states = @order.order_items.collect(&:state)

      return unless order_finished?(item_states)

      clear_sensitive_parameters

      # TO DO: How to determine order state with pre and post order_processes?
      if item_states.include?('Failed') || item_states.include?('Denied')
        @order.mark_failed("Order Failed")
      elsif item_states.all? { |state| state == "Completed" }
        @order.mark_completed("Order Completed")
      elsif item_states.include?('Canceled')
        @order.mark_canceled("Order Canceled")
      end
    end

    def order_finished?(item_states)
      item_states.all? { |state| OrderItem::FINISHED_STATES.include?(state) }
    end

    def clear_sensitive_parameters
      @order.order_items.each(&:clear_sensitive_service_parameters)
    end
  end
end
