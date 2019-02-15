module Api
  module V0x1
    class PortfoliosController < ActionController::API
      def index
        render :json => Portfolio.all
      end

      def add_portfolio_item_to_portfolio
        portfolio = Portfolio.find(params.require(:portfolio_id))
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))
        render :json => portfolio.add_portfolio_item(portfolio_item)
      end

      def create
        portfolio = Portfolio.create!(portfolio_params)
        render :json => portfolio
      rescue ActiveRecord::RecordInvalid => e
        render :json => { :errors => e.message }, :status => :unprocessable_entity
      end

      def update
        portfolio = Portfolio.find(params.require(:portfolio_id))
        portfolio.update!(portfolio_params)

        render :json => portfolio
      end

      def show
        portfolio = Portfolio.find(params.require(:portfolio_id))
        portfolio.update!(portfolio_params)

        render :json => portfolio
      end

      def destroy
        Portfolio.find(params.require(:portfolio_id)).destroy
        head :no_content
      end

      private

      def portfolio_params
        params.permit(:name, :description, :image_url, :enabled)
      end
    end
  end
end
