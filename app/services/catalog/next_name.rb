module Catalog
  class NextName
    attr_reader :next_name

    def initialize(portfolio_item_id, portfolio_id = nil)
      @item = PortfolioItem.find(portfolio_item_id)
      @portfolio = portfolio_id.present? ? Portfolio.find(portfolio_id) : @item.portfolio
    end

    def process
      names = @portfolio.portfolio_items.pluck(:name)
      @next_name = Catalog::NameAdjust.create_copy_name(@item.name, names)

      self
    end
  end
end
