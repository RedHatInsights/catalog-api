module Api
  module V1x2
    class OrdersController < Api::V1x1::OrdersController
      def submit_order
        @order = Order.find(params.require(:order_id))
        authorize(@order)

        service_offering_check

        Catalog::EvaluateOrderProcess.new(@order).process

        order = Catalog::CreateRequestForAppliedInventories.new(@order).process.order
        render :json => order
      end
    end
  end
end
