module Api
  module V1
    class OrderItemsController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      def index
        if params[:order_id]
          collection(Order.find(params.require(:order_id)).order_items)
        else
          collection(OrderItem.all)
        end
      end

      def create
        so = V1x0::Catalog::AddToOrder.new(params)
        render :json => so.process.order_item
      end

      def show
        if params[:order_id] && params[:id]
          render :json => Order.find(params.require(:order_id)).order_items.find(params.require(:id))
        else
          render :json => OrderItem.find(params.require(:id))
        end
      end

      def destroy
        order_item = OrderItem.find(params.require(:id))
        restore_key = V1x0::Catalog::SoftDelete.new(order_item).process.restore_key

        render :json => {:restore_key => restore_key}
      end

      def restore
        order_item = OrderItem.with_discarded.discarded.find(params.require(:order_item_id))
        V1x0::Catalog::SoftDeleteRestore.new(order_item, params.require(:restore_key)).process

        render :json => order_item
      end
    end
  end
end
