module Api
  module V0x1
    class ProviderControlParametersController < ActionController::API
      def index
        so = ServiceCatalog::ProviderControlParameters.new(params.require(:portfolio_item_id))
        render :json => so.process.data
      end
    end
  end
end
