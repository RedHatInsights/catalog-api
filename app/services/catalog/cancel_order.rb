module Catalog
  class CancelOrder
    UNCANCELABLE_STATES = %w[Completed Failed].freeze
    attr_reader :order

    def initialize(order_id)
      @order = Order.find(order_id)
    end

    def process
      raise Catalog::OrderUncancelable if UNCANCELABLE_STATES.include?(@order.state)

      Approval.call do |api|
        # Make API call to approval to cancel the approval request
        # for the order.
      end

      # This will be handled by the approval API event callback,
      # but it's weird to me that we're returning the object right
      # away and it doesn't have the canceled state even though we
      # know it should be cancled right now
      #
      # @order.order_items.update!(:state => 'Canceled')
      # Catalog::OrderStateTransition.new(@order.id).process

      self
    end
  end
end
