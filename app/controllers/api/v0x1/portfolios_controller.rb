module Api
  module V0x1
    class PortfoliosController < ActionController::API
      def index
        render :json => Portfolio.all
      end

      def create
        portfolio = Portfolio.create!(portfolio_params)
        render :json => portfolio
      rescue ActiveRecord::RecordInvalid => e
        render :json => { :errors => e.message }, :status => :unprocessable_entity
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
    end
  end
end
