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

      # TO DO: How to determine order state with pre and post order_processes?
      if item_states.include?('Failed') || item_states.include?('Denied')
        'Failed'
      elsif item_states.all? { |state| state == "Completed" }
        'Completed'
      elsif item_states.include?('Canceled')
        'Canceled'
      else
        'Ordered'
      end
    end
  end
end
