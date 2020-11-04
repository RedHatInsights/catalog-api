module Api
  module V1x3
    class ProgressMessagesController < ApplicationController
      include Mixins::IndexMixin

      SOURCE_TYPES = {"Order" => "order_id", "OrderItem" => "order_item_id"}.freeze

      def index
        source_type = params[:source_type] || "OrderItem"

        # The source_type should also match with request path
        raise Catalog::InvalidParameter unless SOURCE_TYPES.include?(source_type) && request.path.include?(source_type.constantize.table_name)

        collection(source_type.constantize.find(params.require(SOURCE_TYPES[source_type])).progress_messages)
      end
    end
  end
end
