module Api
  module V1x2
    class TagsController < Api::V1x1::TagsController
      private

      def acceptable_params
        {
          :portfolio_id      => Portfolio,
          :portfolio_item_id => PortfolioItem,
          :order_process_id  => OrderProcess
        }
      end
    end
  end
end
