module Catalog
  class ApprovalTransition
    attr_reader :order_item_id
    attr_reader :order_item
    attr_reader :state

    def initialize(order_item_id)
      @order_item = OrderItem.find(order_item_id)
      @approvals = @order_item.approval_requests
    end

    def process
      Insights::API::Common::Request.with_request(@order_item.context.transform_keys(&:to_sym)) do
        state_transitions
      end
      self
    end

    private

    def state_transitions
      if approved?
        @state = "Approved"
        submit_order
      elsif denied?
        @state = "Denied"
        mark_denied
      elsif canceled?
        @state = "Canceled"
        mark_canceled
      else
        @state = "Pending"
        Catalog::OrderStateTransition.new(@order_item.order_id).process
      end
    end

    def submit_order
      @order_item.update_message("info", "Submitting Order #{@order_item.order_id} for provisioning ")
      Catalog::SubmitOrder.new(@order_item.order_id).process
      finalize_order
    rescue Catalog::TopologyError => e
      Rails.logger.error("Error Submitting Order #{@order_item.order_id}, #{e.message}")
      @order_item.update_message("error", "Error Submitting Order #{@order_item.order_id}, #{e.message}")
    end

    def mark_canceled
      finalize_order
      @order_item.update_message("info", "Order #{@order_item.order_id} has been canceled")
      Rails.logger.info("Order #{@order_item.order_id} has been canceled")
    end

    def mark_denied
      finalize_order
      @order_item.update_message("info", "Order #{@order_item.order_id} has been denied")
      Rails.logger.info("Order #{@order_item.order_id} has been denied")
    end

    def finalize_order
      @order_item.update(:state => @state)
      Catalog::OrderStateTransition.new(@order_item.order_id).process
    end

    def approved?
      @approvals.present? && @approvals.all? { |req| req.state == "approved" }
    end

    def denied?
      @approvals.present? && @approvals.any? { |req| req.state == "denied" }
    end

    def canceled?
      @approvals.present? && @approvals.any? { |req| req.state == "canceled" }
    end
  end
end
