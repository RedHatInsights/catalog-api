module Catalog
  class CopyPortfolioItem
    attr_reader :new_portfolio_item

    def initialize(params)
      @portfolio_item = PortfolioItem.find(params[:portfolio_item_id])
      @to_portfolio = Portfolio.find(params[:portfolio_id] || @portfolio_item.portfolio_id)
    end

    def process
      @new_portfolio_item = make_copy
      @to_portfolio.portfolio_items << @new_portfolio_item

      self
    end

    private

    def make_copy
      @portfolio_item.dup.tap do |new_portfolio_item|
        if new_portfolio_item.portfolio_id == @to_portfolio.id
          new_portfolio_item.name = "Copy of " + new_portfolio_item.name
        end

        new_portfolio_item.save
      end
    end
  end
end
