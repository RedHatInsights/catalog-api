module Api
  module V1x0
    class OrderItemsController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      def index
        if params[:order_id]
          collection(Order.find(params.require(:order_id)).order_items)
        else
          collection(OrderItem.all)
        end
      end

      def create
        so = Catalog::AddToOrder.new(params)
        render :json => so.process.order
      end

      def show
        if params[:order_id] && params[:id]
          render :json => Order.find(params.require(:order_id)).order_items.find(params.require(:id))
        else
          render :json => OrderItem.find(params.require(:id))
        end
      end
    end
  end
end
