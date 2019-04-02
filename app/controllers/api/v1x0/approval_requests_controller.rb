module Api
  module V1x0
    class ApprovalRequestsController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      def index
        collection(ApprovalRequest.where(:order_item_id => params.require(:order_item_id)))
      end
    end
  end
end
