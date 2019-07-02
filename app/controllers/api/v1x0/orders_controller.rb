module Api
  module V1x0
    class OrdersController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

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
    end
  end
end
