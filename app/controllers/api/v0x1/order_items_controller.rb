module Api
  module V0x1
    class OrderItemsController < ActionController
      def index
        render :json => Order.find(params.require(:order_id)).order_items
      end

      def show
        render :json => Order.find(params.require(:order_id)).order_items.find(params.require(:order_item_id))
      end
    end
  end
end
