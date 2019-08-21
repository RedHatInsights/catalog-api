module Catalog
  class CancelOrder
    UNCANCELABLE_STATES = %w[Completed Failed Ordered].freeze
    attr_reader :order

    def initialize(order_id)
      @order = Order.find(order_id)
    end

    def process
      raise_uncancelable_error if UNCANCELABLE_STATES.include?(@order.state)

      approval_requests.each do |approval_request|
        Approval.call_action_api do |api|
          api.create_action_by_request(approval_request.first.approval_request_ref, canceled_action)
        end
      end

      self
    rescue Catalog::ApprovalError => e
      Rails.logger.error("Approval error while canceling order: #{e.message}")
      raise_uncancelable_error
    end

    private

    def approval_requests
      @order.order_items.map(&:approval_requests)
    end

    def canceled_action
      @canceled_action ||= ApprovalApiClient::ActionIn.new(:operation => "cancel")
    end

    def raise_uncancelable_error
      error_message = "Order #{@order.id} is not cancelable in its current state: #{@order.state}"
      Rails.logger.error(error_message)
      raise Catalog::OrderUncancelable, error_message
    end
  end
end
