module Catalog
  class OverrideIcon
    attr_reader :icon

    def initialize(icon_id, portfolio_item_id)
      @icon = Icon.find(icon_id)
      @portfolio_item = PortfolioItem.find(portfolio_item_id)
    end

    def process
      # there should only ever be one icon, the others are discarded.
      Catalog::SoftDelete.new(@portfolio_item.icons.first).process
      @portfolio_item.icons << @icon

      self
    end
  end
end
