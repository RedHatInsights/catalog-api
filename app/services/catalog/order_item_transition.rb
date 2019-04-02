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
      ManageIQ::API::Common::Request.with_request(@order_item.context.transform_keys(&:to_sym)) do
        state_transitions
      end
      self
    end

    private

    def state_transitions
      if approved?
        submit_order
        @state = "approved"
      elsif denied?
        mark_denied
        @state = "denied"
      else
        @state = "pending"
      end
    end

    def submit_order
      @order_item.update_message("info", "Submitting Order #{@order_item.order_id} for provisioning ")
      Catalog::SubmitOrder.new(@order_item.order_id).process
    rescue Catalog::TopologyError => e
      Rails.logger.error("Error Submitting Order #{@order_item.order_id}, #{e.message}")
      @order_item.update_message("error", "Error Submitting Order #{@order_item.order_id}, #{e.message}")
    end

    def mark_denied
      @order_item.update!(:state => "Denied")
      @order_item.order.update!(:state => "Denied")
      @order_item.update_message("info", "Order #{@order_item.order_id} has been denied")
    end

    def approved?
      @approvals.present? && @approvals.all? { |req| req.state == "approved" }
    end

    def denied?
      @approvals.present? && @approvals.any? { |req| req.state == "denied" }
    end
  end
end
