module Api
  module V1
    class OrdersController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      def index
        collection(Order.all)
      end

      def create
        render :json => Order.create
      end

      def cancel_order
        canceler = Catalog::CancelOrder.new(params.require(:order_id))
        render :json => canceler.process.order
      end

      def submit_order
        approval = Catalog::CreateApprovalRequest.new(params.require(:order_id))
        render :json => approval.process.order
      end

      def destroy
        order = Order.find(params.require(:id))
        svc = Catalog::SoftDelete.new(order)
        restore_key = svc.process.restore_key

        render :json => {:restore_key => restore_key}
      end

      def restore
        order = Order.with_discarded.discarded.find(params.require(:order_id))
        Catalog::SoftDeleteRestore.new(order, params.require(:restore_key)).process

        render :json => order
      end
    end
  end
end
