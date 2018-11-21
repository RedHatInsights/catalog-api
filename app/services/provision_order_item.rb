class ProvisionOrderItem < TopologyServiceApi
  def process
    provision
  rescue StandardError => e
    Rails.logger.error("Submit Order Item #{e.message}")
    raise
  end

  private

  def order_item
    @order_item ||= OrderItem.find(params.require(:order_item_id))
  end

  def provision
    # TODO Waiting for Topology Service to implement this
    #result = api_instance.submit_provision_order(order_item.provider_control_parameters,
    #                                             order_item.portfolio_item.service_offering_ref,
    #                                             order_item.service_plan_id,
    #                                             order_item.service_parameters)
    order_item.external_ref = "Waiting for toplogy"
    order_item.state        = 'Ordered'
    order_item.ordered_at   = DateTime.now
    order_item.update_message('info', 'Initialized')
    order_item.save!
    order_item.reload
  end
end
