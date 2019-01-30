module Api
  module V0
    class BaseController < ApplicationController
      rescue_from ServiceCatalog::TopologyError, :with => :topology_service_error

      def list_order_item
        render json: Order.find(params.require(:order_id)).
          order_items.find(params.require(:order_item_id)).to_hash
      end

      def list_order_items
        render json: Order.find(params.require(:order_id)).
          order_items.collect(&:to_hash)
      end

      def list_orders
        render json: Order.all.collect(&:to_hash)
      end

      def list_portfolios
        render json: Portfolio.all
      end

      def list_portfolio_items
        render json: PortfolioItem.all
      end

      def fetch_portfolio_with_id
        render json: Portfolio.find(params.require(:portfolio_id))
      end

      def fetch_portfolio_item_from_portfolio
        item = Portfolio.find(params.require(:portfolio_id))
          .portfolio_items.find(params.require(:portfolio_item_id))
        render json: item
      end

      def fetch_portfolio_items_with_id
        render :json => PortfolioItem.find(params.require(:portfolio_item_id))
      end

      def list_progress_messages
        render json: OrderItem.find(params.require(:order_item_id)).progress_messages.collect(&:to_hash)
      end

      def new_order
        render json: Order.create.to_hash
      end

      def submit_order
        so = ServiceCatalog::SubmitOrder.new(params.require(:order_id))
        render :json => so.process.order
      end

      def fetch_plans_with_portfolio_item_id
        so = ServiceCatalog::ServicePlans.new(params.require(:portfolio_item_id))
        render :json => so.process.items
      end

      def fetch_provider_control_parameters
        so = ServiceCatalog::ProviderControlParameters.new(params.require(:portfolio_item_id))
        render :json => so.process.data
      end

      def topology_service_error(err)
        render :json => {:message => err.message}, :status => :internal_server_error
      end
    end
  end
end
