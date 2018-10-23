class AddToOrder
  attr_accessor :params

  def initialize(params)
    @params = params
  end

  def process
    OrderItem.create!(order_item_params)
  end

  def order_item_params
    params.permit(:order_id, :portfolio_item_id, :service_plan_id, :count, service_parameters: {}, provider_control_parameters: {})
  end
end
