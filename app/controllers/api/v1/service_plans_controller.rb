module Api
  module V1
    class ServicePlansController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      def index
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))
        Catalog::ImportServicePlans.new(portfolio_item.id).process if portfolio_item.service_plans.empty?

        collection(portfolio_item.service_plans)
      end

      def show
        plan = ServicePlan.find(params.require(:id))
        render :json => plan
      end

      def base
        plan = ServicePlan.find(params.require(:service_plan_id))
        render :json => plan.base
      end
    end
  end
end
