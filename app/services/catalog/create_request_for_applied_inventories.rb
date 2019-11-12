module Catalog
  class CreateRequestForAppliedInventories
    attr_reader :order

    def initialize(id)
      @order = Order.find_by!(:id => id)
      @item = @order.order_items.first
    end

    def process
      send_request_to_compute_applied_inventories

      @order.update(:state => "Waiting for inventories")
      self
    end

    private

    def send_request_to_compute_applied_inventories
      service_plan = TopologicalInventoryApiClient::AppliedInventoriesParametersServicePlan.new(
        :service_parameters => @item.service_parameters
      )
      TopologicalInventory.call do |api|
        task_id = api.applied_inventories_for_service_offering(service_offering_ref, service_plan).task_id

        @item.update(:topology_task_ref => task_id)
      end
    end

    def service_offering_ref
      @order.order_items.first.portfolio_item.service_offering_ref.to_s
    end
  end
end
