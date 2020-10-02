module Catalog
  class SubmitNextOrderItem
    attr_reader :order

    def initialize(order_id)
      @order_id = order_id
    end

    def process
      @order = Order.find_by!(:id => @order_id)

      # For now simply submit next order_item after previous one is completed
      order_item = @order.order_items.find(&:can_order?)
      return self unless order_item

      Catalog::SubmitOrderItem.new(order_item).process

      @order.update(:state => 'Ordered', :order_request_sent_at => Time.now.utc) unless @order.state == 'Ordered'

      @order.reload
      self
    rescue => e
      Rails.logger.error("Error Submitting Order #{@order_id}: #{e.message}")
      raise
    end
  end
end
