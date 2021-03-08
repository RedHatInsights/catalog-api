module Api
  module V1x0
    module Catalog
      class AddToOrder
        attr_reader :order_item

        def initialize(params)
          @params = params
        end

        def process
          order = Order.find_by!(:id => @params[:order_id])
          @order_item = order.order_items.create!(order_item_params.merge!(:service_plan_ref => service_plan_ref))
          @order_item.update_message("info", "Order item tracking ID (x-rh-insights-request-id): #{@order_item.insights_request_id}")

          # In the earlier design tracking (insights-request-id) is only available in order item since an order can have multiple
          # order_items. In reality an order has only one product order_item that is created upon user's request. Other itsm order_items
          # are auto-created. It makes sense to use the product's tracking ID for the order.
          if order.order_items.size == 1 # the first order_item added is the product
            order.update_message("info", "Order tracking ID (x-rh-insights-request-id): #{@order_item.insights_request_id}")
          end

          self
        end

        private

        def order_item_params
          @params.permit(:order_id, :portfolio_item_id, :count, :service_parameters => {}, :provider_control_parameters => {}).tap do |params|
            params[:name] = PortfolioItem.find(@params[:portfolio_item_id]).name
          end
        end

        def service_plan_ref
          plans = Catalog::ServicePlans.new(@params[:portfolio_item_id]).process.items
          plans.first["id"]
        end
      end
    end
  end
end
