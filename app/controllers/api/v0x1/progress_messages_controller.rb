module Api
  module V0x1
    class ProgressMessagesController < ActionController::API
      def index
        render :json => OrderItem.find(params.require(:order_item_id)).progress_messages
      end
    end
  end
end
