module Catalog
  class CancelOrder
    UNCANCELABLE_STATES = %w[Completed Failed].freeze
    attr_reader :order

    def initialize(order_id)
      @order = Order.find(order_id)
    end

    def process
      raise uncancelable_error if UNCANCELABLE_STATES.include?(@order.state)

      approval_requests.each do |approval_request|
        Approval.call_action_api do |api|
          api.create_action_by_request(approval_request.first.id, canceled_action)
        end
      end

      self
    end

    private

    def approval_requests
      @order.order_items.map(&:approval_requests)
    end

    def canceled_action
      @canceled_action ||= ApprovalApiClient::ActionIn.new(:operation => "cancel")
    end

    def uncancelable_error
      Catalog::OrderUncancelable.new("Order #{@order.id} is not cancelable in its current state")
    end
  end
end
