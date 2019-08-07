module Api
  module V1x0
    class ProgressMessagesController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      def index
        collection(OrderItem.find(params.require(:order_item_id)).progress_messages)
      end

      def destroy
        progress_message = ProgressMessage.find(params.require(:id))
        restore_key = Catalog::SoftDelete.new(progress_message).process.restore_key

        render :json => {:restore_key => restore_key}
      end

      def restore
        progress_message = ProgressMessage.with_discarded.discarded.find(params.require(:progress_message_id))
        Catalog::SoftDeleteRestore.new(progress_message, params.require(:restore_key)).process

        render :json => progress_message
      end
    end
  end
end
