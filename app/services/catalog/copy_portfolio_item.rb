module Catalog
  class CopyPortfolioItem
    attr_reader :new_portfolio_item

    def initialize(params)
      @name = params[:portfolio_item_name]
      @portfolio_item = PortfolioItem.find(params[:portfolio_item_id])

      begin
        @to_portfolio = Portfolio.find(params[:portfolio_id] || @portfolio_item.portfolio_id)
      rescue ActiveRecord::RecordNotFound
        raise Catalog::InvalidParameter, "Portfolio specified not found"
      end
    end

    def process
      @new_portfolio_item = make_copy
      @to_portfolio.portfolio_items << @new_portfolio_item

      self
    end

    private

    def make_copy
      @portfolio_item.dup.tap do |new_portfolio_item|
        new_portfolio_item.name = @name || new_name
        new_portfolio_item.save
      end
    end

    def new_name
      if @portfolio_item.portfolio_id == @to_portfolio.id
        Catalog::NameAdjust.create_copy_name(@portfolio_item.name, @to_portfolio.portfolio_items.pluck(:name))
      else
        @portfolio_item.name
      end
    end
  end
end
