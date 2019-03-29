module Catalog
  class OrderItemTransition
    attr_reader :order_item_id
    attr_reader :order_item
    attr_reader :state

    def initialize(order_item_id)
      @order_item = OrderItem.find(order_item_id)
      @approvals = @order_item.approval_requests
    end

    def process
      if approved?
        submit_order
        @state = "approved"
      elsif denied?
        mark_denied
        @state = "denied"
      else
        @state = "pending"
      end

      self
    end

    private

    def submit_order
      ManageIQ::API::Common::Request.with_request(@order_item.context.transform_keys(&:to_sym)) do
        Catalog::SubmitOrder.new(@order_item.order_id).process
      end
    rescue Catalog::TopologyError => e
      Rails.logger.error("Error Submitting Order #{@order_item.order_id}, #{e.message}")
      @order_item.update_message("info", "Error Submitting Order #{@order_item.order_id}, #{e.message}")
    end

    def mark_denied
      @order_item.update!(:state => "Denied")
      @order_item.order.update!(:state => "Denied")
    end

    def approved?
      @approvals.present? && @approvals.all? { |req| req.state == "approved" }
    end

    def denied?
      @approvals.present? && @approvals.any? { |req| req.state == "denied" }
    end
  end
end
