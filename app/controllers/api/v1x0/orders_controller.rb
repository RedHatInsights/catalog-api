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

      def submit_order
        approval = Catalog::CreateApprovalRequest.new(params.require(:order_id))
        render :json => approval.process.order
      rescue Catalog::ApprovalError => e
        render :json => { :errors => e.message }, :status => :internal_server_error
      end
    end
  end
end
