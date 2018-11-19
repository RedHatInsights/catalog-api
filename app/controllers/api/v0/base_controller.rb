module Api
  module V0
    class BaseController < ApplicationController
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

      def fetch_portfolio_items_with_portfolio
        render json: Portfolio.find(params.require(:portfolio_id)).portfolio_items
      end

      def list_progress_messages
        render json: OrderItem.find(params.require(:order_item_id)).progress_messages.collect(&:to_hash)
      end

      def new_order
        render json: Order.create.to_hash
      end

      def submit_order
        render json: CreateApprovalRequest.new(:params => params, :request => request).process.to_hash
      end

      def fetch_plans_with_portfolio_item_id
        render json: ServicePlans.new(params).process
      end
    end
  end
end
