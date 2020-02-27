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
          :platform  => platform(@order_item.portfolio_item),
          :params    => @order_item.service_parameters
        }
        request.tag_resources = all_tag_resources
      end

      self
    end

    private

    def platform(portfolio_item)
      service_offering = TopologicalInventory.call do |api_instance|
        api_instance.show_service_offering(portfolio_item.service_offering_ref)
      end
      source = Sources.call do |api_instance|
        api_instance.show_source(service_offering.source_id)
      end
      source.name
    end

    def all_tag_resources
      local_tag_resources = Tags::CollectLocalOrderResources.new(:order_id => @order.id).process.tag_resources
      remote_tag_resources = Tags::Topology::RemoteInventory.new(@task).process.tag_resources

      local_tag_resources + remote_tag_resources
    end
  end
end
