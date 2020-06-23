module Api
  module V1x0
    class ProgressMessagesController < ApplicationController
      include Mixins::IndexMixin

      def index
        collection(OrderItem.find(params.require(:order_item_id)).progress_messages)
      end
    end
  end
end
