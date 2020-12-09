module Catalog
  class CreateRequestBodyFrom
    include Platform
    attr_reader :result

    def initialize(order, order_item, task, tag_resources)
      @order = order
      @order_item = order_item
      @task = task
      @tag_resources = tag_resources
    end

    def process
      @result = ApprovalApiClient::RequestIn.new.tap do |request|
        request.name      = @order_item.portfolio_item.name
        request.content   = {
          :product   => @order_item.portfolio_item.name,
          :portfolio => @order_item.portfolio_item.portfolio.name,
          :order_id  => @order_item.order_id.to_s,
          :platform  => platform(@order_item.portfolio_item).name,
          :params    => @order_item.service_parameters
        }
        request.tag_resources = @tag_resources
      end

      self
    end
  end
end
