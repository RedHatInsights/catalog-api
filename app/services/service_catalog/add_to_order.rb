module ServiceCatalog
  class AddToOrder
    attr_reader :order

    def initialize(params)
      @params = params
    end

    def process
      @order = Order.find_by!(:id => @params[:order_id])
      order.order_items << OrderItem.create!(order_item_params)
      self
    end

    private

    def order_item_params
      @params.permit(:order_id, :portfolio_item_id, :service_plan_ref, :count, :service_parameters => {}, :provider_control_parameters => {})
    end
  end
end
