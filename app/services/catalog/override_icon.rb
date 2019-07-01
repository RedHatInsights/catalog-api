module Catalog
  class OverrideIcon
    attr_reader :icon

    def initialize(icon_id, portfolio_item_id)
      @icon = Icon.find(icon_id)
      @portfolio_item = PortfolioItem.find(portfolio_item_id)
    end

    def process
      @portfolio_item.icon.destroy
      @portfolio_item.icon = @icon

      self
    end
  end
end
