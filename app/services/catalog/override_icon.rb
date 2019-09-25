module Catalog
  class OverrideIcon
    attr_reader :icon

    def initialize(icon_id, args)
      @icon = Icon.find(icon_id)

      if args.key?(:portfolio_item_id)
        @obj = PortfolioItem.find(args[:portfolio_item_id])
      elsif args.key?(:portfolio_id)
        @obj = Portfolio.find(args[:portfolio_id])
      end
    end

    def process
      # there should only ever be one icon, the others are discarded.
      Catalog::SoftDelete.new(@obj.icons.first).process
      @obj.icons << @icon

      self
    end
  end
end
