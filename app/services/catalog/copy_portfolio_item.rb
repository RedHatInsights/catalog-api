module Catalog
  class CopyPortfolioItem
    attr_reader :new_portfolio_item

    def initialize(params)
      @portfolio_item = PortfolioItem.find(params[:portfolio_item_id])
      @params = params

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
        new_portfolio_item.name = @params[:portfolio_item_name] || new_name(@portfolio_item.name, :name)
        new_portfolio_item.display_name = @params[:portfolio_item_name] || new_name(@portfolio_item.display_name, :display_name)
        new_portfolio_item.save
      end
    end

    def new_name(name, field)
      portfolio_names = @to_portfolio.portfolio_items.pluck(field)
      if portfolio_names.include?(name)
        Catalog::NameAdjust.create_copy_name(name, portfolio_names)
      else
        name
      end
    end
  end
end
