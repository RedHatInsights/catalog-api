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
      rescue ServiceCatalog::TopologyError => e
        render :json => { :errors => e.message }, :status => :not_found
      end

      def show
        render :json => PortfolioItem.find(params.require(:id))
      end

      def destroy
        PortfolioItem.find(params.require(:id)).destroy
        head :no_content
      end

      private

      def portfolio_item_params
        params.permit(:service_offering_ref)
      end
    end
  end
end
