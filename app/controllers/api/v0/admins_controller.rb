module Api
  module V0
    class AdminsController < BaseController
      def add_portfolio
        portfolio = Portfolio.create!(portfolio_params)
        render json: portfolio
      end

      def add_portfolio_item_to_portfolio
        portfolio = Portfolio.find(portfolio_id_param[:portfolio_id])
        render json: portfolio.add_portfolio_item(portfolio_item_id_param[:portfolio_item_id])
      end

      def add_portfolio_item
        render json: PortfolioItem.create!(portfolio_item_params)
      end

      def add_to_order
        render json: AddToOrder.new(params).process.to_hash
      end

      private
      def portfolio_item_params
        params.permit(:service_offering_ref)
      end

      def portfolio_params
        params.permit(:name, :description, :image_url, :enabled)
      end

      def portfolio_id_param
        params.permit(:portfolio_id)
      end

      def portfolio_item_id_param
        params.permit(:portfolio_item_id)
      end
    end
  end
end
