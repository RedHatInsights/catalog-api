module Api
  module V0x1
    class OrdersController < ApplicationController
      include Api::V0x1::Mixins::IndexMixin

      def index
        collection(Order.all)
      end

      def create
        render :json => Order.create
      end

      def submit_order
        approval = Catalog::CreateApprovalRequest.new(params.require(:order_id))
        render :json => approval.process.order
      end
    end
  end
end
