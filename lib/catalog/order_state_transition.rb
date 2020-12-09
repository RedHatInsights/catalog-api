module Catalog
  class OrderStateTransition
    attr_reader :state

    def initialize(order)
      @order = order
    end

    def process
      @state = determine_order_state
      @order.update!(:state => @state)

      self
    end

    private

    def determine_order_state
      item_states = @order.order_items.collect(&:state)

      return 'Ordered' unless order_finished?(item_states)

      clear_sensitive_parameters

      # TO DO: How to determine order state with pre and post order_processes?
      if item_states.include?('Failed') || item_states.include?('Denied')
        @order.update_message("error", "Order Failed")
        'Failed'
      elsif item_states.all? { |state| state == "Completed" }
        @order.update_message("info", "Order Completed")
        'Completed'
      elsif item_states.include?('Canceled')
        # Message of 'Order Canceled' has been recorded
        'Canceled'
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
