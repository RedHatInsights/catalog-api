module Api
  module V1x3
    class OrderProcessesController < Api::V1x2::OrderProcessesController
      def update_return_portfolio_item
        order_process = update_association(:return_portfolio_item)

        render :json => order_process
      end

      def reposition
        order_process = OrderProcess.find(params.require(:id))
        authorize(order_process)

        ::Catalog::OrderProcessSequence.new(order_process, increment_param).process

        head :no_content
      end

      private

      def increment_param
        raise ::Catalog::InvalidParameter, "Cannot have both increment and placement params set" if params[:placement] && params[:increment]

        raise ::Catalog::InvalidParameter, "Neither increment nor placement parameter is set" unless params[:placement] || params[:increment]

        params[:placement] || params[:increment]
      end
    end
  end
end
