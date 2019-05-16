module Catalog
  class CopyPortfolio
    attr_reader :new_portfolio

    def initialize(params)
      @name = params[:portfolio_name]
      @portfolio = Portfolio.find(params[:portfolio_id])
    end

    def process
      @new_portfolio = make_copy

      self
    end

    private

    def make_copy
      @portfolio.dup.tap do |new_portfolio|
        new_portfolio.name = @name || Catalog::NameAdjust.create_copy_name(@portfolio.name, Portfolio.all.pluck(:name))
        new_portfolio.save!

        copy_portfolio_items(new_portfolio.id)
      end
    end

    def copy_portfolio_items(portfolio_id)
      @portfolio.portfolio_items.each do |item|
        Catalog::CopyPortfolioItem.new(:portfolio_item_id => item.id, :portfolio_id => portfolio_id).process
      end
    end
  end
end
