class SendProvisionWebhook
  attr_reader :params
  attr_reader :request
  TITLE = "Provision Webhook".freeze
  def initialize(params, request)
    @params = params
    @request = request
  end

  def process
    if exists?
      post_webhook
    else
      raise ArgumentError, "Webhook not found"
    end
  end

  private

  def post_webhook
    wh_options = JSON.parse(webhook.parameters)
    PostWebhook.new(wh_options).process(body.to_json)
  rescue StandardError => e
    Rails.logger.error("SendProvisionWebhook #{e.message}")
    raise
  end

  def order_item
    @order_item ||= OrderItem.find(params[:order_item_id])
  end

  def portfolio_item
    @portfolio_item ||= PortfolioItem.find(order_item.portfolio_item_id)
  end

  def body
    {
      'title'       => title,
      'description' => portfolio_item.name,
      'parameters'  => order_item.service_parameters
    }
  end

  def title
    self.class::TITLE
  end

  def webhook
    raise NotImplementedError, "webhook should be implemented by subclass"
  end

  def exists?
    raise NotImplementedError, "exists? should be implemented by subclass"
  end
end
