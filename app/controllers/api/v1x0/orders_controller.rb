module Api
  module V1x0
    class OrdersController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::ServiceOfferingMixin
      include Mixins::ShowMixin

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
        @order = Order.find(params.require(:order_id))
        authorize(@order)

        service_offering_check

        order = Catalog::CreateRequestForAppliedInventories.new(@order).process.order
        render :json => order
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
