module Api
  module V1x0
    class ApprovalRequestsController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      def index
        collection(OrderItem.find(params.require(:order_item_id)).approval_requests)
      end
    end
  end
end
