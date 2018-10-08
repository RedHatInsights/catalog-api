class AdminsController < BaseController
  def add_provider
    object = Provider.create(:name       => params[:name],
                             :url        => params[:url],
                             :token      => params[:token],
                             :user       => params[:user],
                             :password   => params[:password],
                             :verify_ssl => params.fetch(:verify_ssl, true))
    render json: object.to_hash
  end

  def add_portfolio
    portfolio = Portfolio.create!(portfolio_params)
    render json: portfolio
  end

  def add_portfolio_item_to_portfolio
    portfolio = Portfolio.find_by(id: params[:portfolio_id])
    render json: portfolio.add_portfolio_item(params[:portfolio_item_id])
  end

  def add_portfolio_item
    portfolio_item = PortfolioItem.create!(portfolio_item_params)
    render json: portfolio_item
  end

  def add_to_order
    order = Order.find(params['order_id'])
    hash_parameters = []
    params['parameters'].each do |p|
      hash_parameters << {:name => p['name'], :value => p['value'], :format => p['format'],
                          :type => p['type'] }
    end
    order_item = OrderItem.create(:order_id    => order.id,
                                  :catalog_id  => params['catalog_id'],
                                  :plan_id     => params['plan_id'],
                                  :provider_id => params['provider_id'],
                                  :count       => params['count'] || 1,
                                  :parameters  => hash_parameters)
    render json: {"item_id" => order_item.id}
  end

  private
    def portfolio_item_params
      params.permit(:favorite, :name, :description, :orphan, :state, :portfolio_id)
    end

    def portfolio_params
      params.permit(:name, :description, :image_url, :enabled)
    end
end
