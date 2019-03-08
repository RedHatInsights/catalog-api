module Api
  module V0x1
    class ProviderControlParametersController < ApplicationController
      def index
        so = Catalog::ProviderControlParameters.new(params.require(:portfolio_item_id))
        render :json => so.process.data
      end
    end
  end
end
