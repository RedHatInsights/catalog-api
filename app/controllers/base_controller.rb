class BaseController < ApplicationController
  def catalog_items
    result = Provider.all.collect { |prov| prov.fetch_catalog_items }.flatten
    render json: result
  end

  def catalog_plan_parameters
    prov = Provider.where(:id => params['provider_id']).first
    result = prov.fetch_catalog_plan_parameters(params['catalog_id'], params['plan_id']) if prov
    render json: result
  end

  def catalog_plan_schema
    prov = Provider.where(:id => params['provider_id']).first
    result = prov.fetch_catalog_plan_schema(params['catalog_id'], params['plan_id']) if prov
    render json: result
  end

  def fetch_catalog_item_with_provider
    prov = Provider.where(:id => params['provider_id']).first
    result = prov.fetch_catalog_items(params['catalog_id']) if prov
    render json: result
  end

  def fetch_catalog_item_with_provider_and_catalog_id
    fetch_catalog_item_with_provider
  end

  def fetch_plans_with_provider_and_catalog_id
    prov = Provider.where(:id => params['provider_id']).first
    result = prov.fetch_catalog_plans(params['catalog_id']) if prov
    render json: result
  end

  def list_order_item
    item = OrderItem.where('id = ? and order_id = ?',
                           params['order_item_id'], params['order_id']).first
    render json: item.to_hash
  end

  def list_order_items
    render json: OrderItem.where(:order_id => params['order_id']).collect(&:to_hash)
  end

  def list_orders
    render json: Order.all.collect(&:to_hash)
  end

  def list_portfolios
    portfolios = Portfolio.all
    render json: portfolios
  end

  def list_portfolio_items
    render json: PortfolioItem.all
  end

  def fetch_portfolio_with_id
    render json: Portfolio.find_by(:id => params[:portfolio_id])
  end

  def fetch_portfolio_item_from_portfolio
    items = Portfolio.find(params[:portfolio_id])
                     .portfolio_items.find_by(:id => params[:portfolio_item_id])
    render json: items
  end

  def fetch_portfolio_items_with_portfolio
    render json: Portfolio.find(params[:portfolio_id]).portfolio_items
  end

  def list_progress_messages
    render json: ProgressMessage.where(:order_item_id => params['order_item_id']).collect(&:to_hash)
  end

  def list_providers
    render json: Provider.all.collect(&:to_hash)
  end

  def new_order
    render json: Order.create.to_hash
  end

  def submit_order
    render json: SubmitOrder.new(params).process.to_hash
  end

  def fetch_plans_with_portfolio_item_id
    render json: ServicePlans.new(params).process
  end
end
