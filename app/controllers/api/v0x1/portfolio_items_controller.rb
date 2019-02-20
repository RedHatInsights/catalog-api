module Api
  module V0x1
    class PortfolioItemsController < ApplicationController
      include Api::V0x1::Mixins::IndexMixin

      def index
        if params[:portfolio_id]
          collection(PortfolioItem.where(:portfolio_id => params.require(:portfolio_id)))
        else
          collection(PortfolioItem.all)
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
