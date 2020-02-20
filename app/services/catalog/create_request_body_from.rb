module Catalog
  class CreateRequestBodyFrom
    attr_reader :result

    def initialize(order, order_item, task)
      @order = order
      @order_item = order_item
      @task = task
    end

    def process
      @result = ApprovalApiClient::RequestIn.new.tap do |request|
        request.name      = @order_item.portfolio_item.name
        request.content   = {
          :product   => @order_item.portfolio_item.name,
          :portfolio => @order_item.portfolio_item.portfolio.name,
          :order_id  => @order_item.order_id.to_s,
          :params    => @order_item.service_parameters
        }
        request.tag_resources = all_tag_resources
      end

      self
    end

    private

    def all_tag_resources
      local_tag_resources = Tags::CollectLocalOrderResources.new(:order_id => @order.id).process.tag_resources
      remote_tag_resources = Tags::Topology::RemoteInventory.new(@task).process.tag_resources

      local_tag_resources + remote_tag_resources
    end
  end
end
