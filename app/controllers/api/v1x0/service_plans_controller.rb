module Api
  module V1x0
    class ServicePlansController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      def index
        so = Catalog::ServicePlans.new(params.require(:portfolio_item_id))
        render :json => so.process.items
      end
    end
  end
end
