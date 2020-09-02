module Api
  module V1x2
    class PortfolioItemsController < Api::V1x1::PortfolioItemsController
      def show
        portfolio_item = model.find_by(:id => params.require(:id)) || find_in_discarded_items

        raise ActiveRecord::RecordNotFound unless portfolio_item

        render_item(portfolio_item)
      end

      private

      def find_in_discarded_items
        model.with_discarded.discarded.find_by(:id => params.require(:id)) if params[:show_discarded] == "true"
      end
    end
  end
end
