class SubmitOrder < TopologyServiceApi
  def process
    order.order_items.each do |order_item|
      submit_order_item(order_item)
    end 
    order.update_attributes(:state => 'Ordered', :ordered_at => DateTime.now())
    order
  rescue StandardError => e
    Rails.logger.error("Submit Order #{e.message}")
    raise
  end

  private

  def order
    @order ||= Order.find_by!(:id => params[:order_id])
  end

  def submit_order_item(order_item)
    sor = service_offering_ref(order_item.portfolio_item_id)
    # TODO Waiting for Topology Service to implement this
    #result = api_instance.submit_provision_order(order_item.provider_control_parameters,
    #                                             sor,
    #                                             order_item.service_plan_id,
    #                                             order_item.service_parameters)
    order_item.external_ref = "Waiting for toplogy"
    order_item.state        = 'Ordered'
    order_item.ordered_at   = DateTime.now
    order_item.update_message('info', 'Initialized')
    order_item.save!
  end

  def service_offering_ref(portfolio_item_id)
    PortfolioItem.find_by!(:id => portfolio_item_id).service_offering_ref
  end
end
