module Api
  module V1x2
    module Catalog
      class OrderProcessAssociator
        attr_reader :order_process

        def initialize(order_process, portfolio_item_id, association)
          @order_process = order_process
          @portfolio_item = PortfolioItem.find(portfolio_item_id)
          @association = association
        end

        def process
          @order_process.update(@association => @portfolio_item)

          self
        end
      end
    end
  end
end
