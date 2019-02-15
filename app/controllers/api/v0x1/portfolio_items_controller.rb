module Api
  module V0x1
    class PortfolioItemsController < ActionController::API
      def index
        if params[:portfolio_id]
          render :json => PortfolioItem.where(:portfolio_id => params.require(:portfolio_id))
        else
          render :json => PortfolioItem.all
        end
      end

      def create
        so = ServiceOffering::AddToPortfolioItem.new(portfolio_item_params)
        render :json => so.process.item
      end

      def show
        render :json => Portfolio.find(params.require(:portfolio_id))
      end

      def destroy
        PortfolioItem.find(params.require(:portfolio_item_id)).destroy
        head :no_content
      end
    end
  end
end

