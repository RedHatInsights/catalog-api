module Api
  module V1x2
    module Catalog
      class CreateRequestForAppliedInventories < Api::V1x1::Catalog::CreateRequestForAppliedInventories
        def initialize(order)
          @order = order
          @item = @order.order_items.where(:process_scope => "applicable").first
        end
      end
    end
  end
end
