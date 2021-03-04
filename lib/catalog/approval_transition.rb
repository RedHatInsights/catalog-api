module Catalog
  class ApprovalTransition
    attr_reader :order_item_id, :order_item, :state

    def initialize(order_item_id)
      @order_item = OrderItem.find(order_item_id)
      @approvals = @order_item.approval_requests
    end

    def process
      state_transitions
      self
    end

    private

    def state_transitions
      if approved?
        @state = "Approved"
        submit_order
      elsif denied?
        @state = "Denied"
        cancel_all
      elsif canceled?
        @state = "Canceled"
        cancel_all
      elsif error?
        @state = "Failed"
        cancel_all
      else
        @state = "Pending"
      end
    end

    def submit_order
      @order_item.update(:state => "Approved")
      update_order
      @order_item.order.mark_ordered("Submitting Order for provisioning")
      Catalog::SubmitNextOrderItem.new(@order_item.order_id).process
    end

    def cancel_all
      level = @state == "Failed" ? "error" : "info"
      @order_item.order.order_items.each do |item|
        state = item == @order_item ? @state : "Canceled"
        item.update_message(level, "Order Item #{state} because approval status is #{@state}")
        Rails.logger.send(level, "Order Item #{item.id} marked as #{state} because approval status is #{@state}")
        item.update(:state => state)
      end
      update_order
    end

    def update_order
      level = @state == "Failed" ? "error" : "info"
      approval_reasons = reasons
      if approval_reasons.blank?
        @order_item.order.update_message(level, "Approval Request finished with status #{@state}")
        Rails.logger.send(level, "Approval request for order #{@order_item.order_id} with status #{@state}")
      else
        @order_item.order.update_message(level, "Approval Request finished with status #{@state} and reason #{approval_reasons}")
        Rails.logger.send(level, "Approval request for order #{@order_item.order_id} with status #{@state} and reason #{approval_reasons}")
      end
      Catalog::OrderStateTransition.new(@order_item.order).process unless @state == "Approved"
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

    def error?
      @approvals.present? && @approvals.any? { |req| req.state == "error" }
    end

    def reasons
      return "" if @approvals.blank?

      @approvals.collect(&:reason).compact.join('. ')
    end
  end
end
