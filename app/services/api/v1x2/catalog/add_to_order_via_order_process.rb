module Api
  module V1x2
    module Catalog
      class AddToOrderViaOrderProcess < Api::V1x0::Catalog::AddToOrder
        attr_reader :order_item

        private

        def order_item_params
          @params
        end
      end
    end
  end
end
