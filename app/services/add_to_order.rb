class AddToOrder
  attr_accessor :params

  def initialize(params)
    @params = params
  end

  def process
    order.order_items << OrderItem.create!(order_item_params)
    order
  end

  def order_item_params
    params.permit(:order_id, :portfolio_item_id, :service_plan_ref, :count, service_parameters: {}, provider_control_parameters: {})
  end

  def order
    Order.find_by!(:id => params[:order_id])
  end
end
