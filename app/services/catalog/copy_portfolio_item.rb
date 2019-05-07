module Catalog
  class CopyPortfolioItem
    attr_reader :new_portfolio_item

    def initialize(params)
      @portfolio_item = PortfolioItem.find(params[:portfolio_item_id])
      @to_portfolio = Portfolio.find_by!(:id => params[:portfolio_id]) if params[:portfolio_id].present?
    end

    def process
      @new_portfolio_item = make_copy
      @to_portfolio.portfolio_items << @new_portfolio_item

      self
    end

    private

    def make_copy
      new_portfolio_item = @portfolio_item.dup

      if new_portfolio_item.portfolio_id == @to_portfolio.id
        new_portfolio_item.name = "Copy of " + new_portfolio_item.name
      end

      new_portfolio_item.save
      new_portfolio_item
    end
  end
end
