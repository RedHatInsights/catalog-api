module Api
  module V0x1
    class ProgressMessagesController < ApplicationController
      include Api::V0x1::Mixins::IndexMixin

      def index
        collection(OrderItem.find(params.require(:order_item_id)).progress_messages)
      end
    end
  end
end
