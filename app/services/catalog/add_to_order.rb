module Catalog
  class AddToOrder
    attr_reader :order_item

    def initialize(params)
      @params = params
    end

    def process
      order = Order.find_by!(:id => @params[:order_id])
      @params.delete(:service_plan_ref)
      @order_item = order.order_items.create!(order_item_params.merge!(:service_plan_ref => service_plan_ref))
      self
    end

    private

    def order_item_params
      @params.permit(:order_id, :portfolio_item_id, :count, :service_parameters => {}, :provider_control_parameters => {})
    end

    def service_plan_ref
      plans = Catalog::ServicePlans.new(@params[:portfolio_item_id]).process.items
      plans.first["id"]
    end
  end
end
