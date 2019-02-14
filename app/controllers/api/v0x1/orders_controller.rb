module Api
  module V0x1
    class OrdersController < ActionController::API
      def index
        render :json => Order.all
      end

      def create
        render :json => Order.create
      end

      def submit
        so = ServiceCatalog::SubmitOrder.new(params.require(:order_id))
        render :json => so.process.order
      end
    end
  end
end
