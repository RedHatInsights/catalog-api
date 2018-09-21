class Admin::PortfoliosController < AdminsController
  def add_portfolio
    portfolio = Portfolio.create(:name        => params[:name],
                                 :description => params[:description],
                                 :image_url   => params[:url],
                                 :enabled     => params[:enabled])
    render json: portfolio
  end

  def list_portfolios
    portfolios = Portfolio.all
    render json: portfolios
  end

  def fetch_portfolio_with_id
    item = Portfolio.where(:id => params[:portfolio_id]).first
    render json: item
  end

  def fetch_portfolio_items_with_portfolio
    portfolio_items = Portfolio.where(id: params[:portfolio_id]).first
                               .portfolio_items
    render json: portfolio_items
  end

  def fetch_portfolio_item_from_portfolio
    portfolio_item = Portfolio.where(id: params[:portfolio_id], porfolio_item_id: params[:portfolio_item_id])
                              .includes(:portfolio_items)
    render json: portfolio_item
  end

  def add_portfolio_item_to_portfolio
    portfolio = Portfolio.find_by(id: params[:portfolio_id])
    render json: portfolio.add_portfolio_item(params[:portfolio_item_id])
  end

  def add_portfolio_item
    portfolio_item = PortfolioItem.create!(
        favorite: params[:favorite],
        name: params[:name],
        description: params[:description],
        orphan: params[:orphan],
        state: params[:state]
    )
    render json: portfolio_item
  end

  def list_portfolio_items
    portfolio_items = PortfolioItem.all
    render json: portfolio_items
  end
end
