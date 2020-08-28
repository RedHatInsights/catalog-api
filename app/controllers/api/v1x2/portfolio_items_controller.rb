module Api
  module V1x2
    class PortfolioItemsController < Api::V1x1::PortfolioItemsController
      def show
        portfolio_item = if params[:showDiscarded] == "true"
                           model.with_discarded.discarded.find(params.require(:id))
                         else
                           model.find(params.require(:id))
                         end

        authorize(portfolio_item)

        json = portfolio_item.as_json(:prefixes => _prefixes, :template => action_name)
        json['metadata']['orderable'] = Catalog::PortfolioItemOrderable.new(portfolio_item).process.result
        render :json => json
      end
    end
  end
end
