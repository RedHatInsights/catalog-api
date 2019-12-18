module Api
  module V1
    class OrdersController < ApplicationController
      include Api::V1::Mixins::IndexMixin
      before_action :read_access_check, :only => %i[show]
      before_action :service_offering_check, :only => %i[submit_order]

      def index
        collection(Order.all)
      end

      def show
        render :json => Order.find(params.require(:id))
      end

      def create
        render :json => Order.create
      end

      def cancel_order
        canceler = Catalog::CancelOrder.new(params.require(:order_id))
        render :json => canceler.process.order
      end

      def submit_order
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

      private

      def service_offering_check
        order_id = params.require(:order_id)
        service_offering_service = Catalog::ServiceOffering.new(order_id).process
        if service_offering_service.archived
          Rails.logger.error("Service offering for order #{order_id} has been archived and can no longer be ordered")
          raise Catalog::ServiceOfferingArchived, "Service offering for order #{order_id} has been archived and can no longer be ordered"
        else
          @order = service_offering_service.order
        end
      end
    end
  end
end
