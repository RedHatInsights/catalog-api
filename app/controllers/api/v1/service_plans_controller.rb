module Api
  module V1
    class ServicePlansController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      def index
        so = Catalog::ServicePlans.new(params.require(:portfolio_item_id))
        render :json => so.process.items
      end
    end
  end
end
