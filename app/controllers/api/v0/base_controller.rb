module Api
  module V0
    class BaseController < ApplicationController
      def list_order_item
        item = OrderItem.where('id = ? and order_id = ?',
                               params['order_item_id'], params['order_id']).first
        render json: item.to_hash
      end

      def list_order_items
        render json: OrderItem.where(:order_id => params['order_id']).collect(&:to_hash)
      end

      def list_orders
        render json: Order.all.collect(&:to_hash)
      end

      def list_portfolios
        portfolios = Portfolio.all
        render json: portfolios
      end

      def list_portfolio_items
        render json: PortfolioItem.all
      end

      def fetch_portfolio_with_id
        render json: Portfolio.find(params[:portfolio_id])
      end

      def fetch_portfolio_item_from_portfolio
        items = Portfolio.find(params[:portfolio_id])
                         .portfolio_items.find_by(:id => params[:portfolio_item_id])
        render json: items
      end

      def fetch_portfolio_items_with_portfolio
        render json: Portfolio.find(params[:portfolio_id]).portfolio_items
      end

      def list_progress_messages
        render json: ProgressMessage.where(:order_item_id => params['order_item_id']).collect(&:to_hash)
      end

      def new_order
        render json: Order.create.to_hash
      end

      def submit_order
        render json: SubmitOrder.new(params).process.to_hash
      end

      def fetch_plans_with_portfolio_item_id
        render json: ServicePlans.new(params).process
      end
    end
  end
end
