module Api
  module V0
    class AdminsController < BaseController
      def add_portfolio
        portfolio = Portfolio.create!(portfolio_params)
        render json: portfolio
      rescue ActiveRecord::RecordInvalid => e
        render :json => { :errors => e.message }, :status => :unprocessable_entity
      end

      def add_portfolio_item_to_portfolio
        portfolio = Portfolio.find(params.require(:portfolio_id))
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))
        render json: portfolio.add_portfolio_item(portfolio_item)
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
    end
  end
end
