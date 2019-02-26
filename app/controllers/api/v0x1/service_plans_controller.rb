module Api
  module V0x1
    class ServicePlansController < ApplicationController
      include Api::V0x1::Mixins::IndexMixin

      def index
        so = ServiceCatalog::ServicePlans.new(params.require(:portfolio_item_id))
        render :json => so.process.items
      end
    end
  end
end
