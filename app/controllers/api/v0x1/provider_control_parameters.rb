module Api
  module V0x1
    class ProviderControlParametersController < ApplicationController
      include Api::V0x1::Mixins::IndexMixin

      def index
        so = ServiceCatalog::ProviderControlParameters.new(params.require(:portfolio_item_id))
        collection(so.process.data)
      end
    end
  end
end
