module Api
  module V1
    class ApprovalRequestsController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      def index
        collection(OrderItem.find(params.require(:order_item_id)).approval_requests)
      end
    end
  end
end
