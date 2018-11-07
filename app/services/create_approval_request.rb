class CreateApprovalRequest < ApprovalServiceApi
  def process
    order.order_items.each do |order_item|
      submit_approval_request(order_item)
    end
    order.update(:state => 'Ordered', :ordered_at => DateTime.now.utc)
    order
  rescue StandardError => e
    Rails.logger.error("CreateApprovalRequest #{e.message}")
    raise
  end

  private

  def submit_approval_request(order_item)
    pf_item = portfolio_item(order_item)
    body = request_body(pf_item, order_item)
    begin
      request = api_instance.add_request(pf_item.approval_workflow_ref, body)
      order_item.approval_request_ref = request.id
      order_item.save!
    rescue ApprovalAPIClient::ApiError => e
      Rails.logger.error("UsersApi->add_request #{e.message}")
      raise
    end
  end

  def order
    @order ||= Order.find_by!(:id => params[:order_id])
  end

  def portfolio_item(order_item)
    PortfolioItem.find_by!(:id => order_item.portfolio_item_id)
  end

  def request_body(pf_item, order_item)
    o_params = ActionController::Parameters.new('order_item_id' => order_item.id)
    content = OrderItemSanitizedParameters.new(o_params).process
    ApprovalAPIClient::Request.new(
      'requester' => username,
      'name'      => pf_item.name,
      'content'   => content.to_json
    )
  end

  def username
    raise "Missing Header x-rh-auth-identity" unless request.headers.key?('x-rh-auth-identity')
    x_rh_auth_identity = JSON.parse(Base64.decode64(request.headers['x-rh-auth-identity']))
    x_rh_auth_identity.key?('identity') ? x_rh_auth_identity['identity'].fetch('username', "unknown") : "unknown"
  end
end
