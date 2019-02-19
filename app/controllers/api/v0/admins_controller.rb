module Api
  module V0
    class AdminsController < BaseController
      def add_portfolio
        portfolio = Portfolio.create!(portfolio_params)
        render :json => portfolio
      rescue ActiveRecord::RecordInvalid => e
        render :json => { :errors => e.message }, :status => :unprocessable_entity
      end

      def edit_portfolio
        portfolio = Portfolio.find(params.require(:portfolio_id))
        portfolio.update!(portfolio_params)

        render :json => portfolio
      end

      def destroy_portfolio
        Portfolio.find(params.require(:portfolio_id)).destroy
        head :no_content
      end

      def add_portfolio_item_to_portfolio
        portfolio = Portfolio.find(params.require(:portfolio_id))
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))
        render :json => portfolio.add_portfolio_item(portfolio_item)
      end

      def add_portfolio_item
        so = ServiceOffering::AddToPortfolioItem.new(portfolio_item_params)
        render :json => so.process.item
      rescue ServiceCatalog::TopologyError => e
        render :json => { :errors => e.message }, :status => :not_found
      end

      def add_to_order
        so = ServiceCatalog::AddToOrder.new(params)
        render :json => so.process.order
      end

      def destroy_portfolio_item
        PortfolioItem.find(params.require(:portfolio_item_id)).discard
        head :no_content
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
