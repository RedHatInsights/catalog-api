module Api
  module V1x2
    module Catalog
      class OrderProcessDissociator
        ASSOCIATION_MAP = {"before" => :before_portfolio_item, "after" => :after_portfolio_item, "return" => :return_portfolio_item}.freeze

        attr_reader :order_process

        def initialize(order_process, associations_to_remove)
          @order_process = order_process
          @associations_to_remove = associations_to_remove
        end

        def process
          map_associations_to_remove.each do |association|
            @order_process.update(association => nil)
          end

          self
        end

        private

        def map_associations_to_remove
          @associations_to_remove.collect do |association|
            ASSOCIATION_MAP[association]
          end
        end
      end
    end
  end
end
