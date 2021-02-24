module Api
  module V1x3
    class OrderProcessesController < Api::V1x2::OrderProcessesController
      def update_return_portfolio_item
        order_process = update_association(:return_portfolio_item)

        render :json => order_process
      end
    end
  end
end
