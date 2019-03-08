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
        so = Catalog::SubmitOrder.new(params.require(:order_id))
        render :json => so.process.order
      end
    end
  end
end
