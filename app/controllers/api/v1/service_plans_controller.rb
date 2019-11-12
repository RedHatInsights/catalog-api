module Api
  module V1
    class ServicePlansController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      def index
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))

        if portfolio_item.service_plans.empty?
          render :json => Catalog::ServicePlans.new(portfolio_item.id).process.items
        else
          render :json => portfolio_item.service_plans
        end
      end

      def create
        svc = Catalog::ImportServicePlans.new(params.require(:portfolio_item_id))
        render :json => svc.process.service_plans
      end

      def show
        plan = ServicePlan.find(params.require(:id))
        render :json => plan
      end

      def base
        plan = ServicePlan.find(params.require(:service_plan_id))
        render :json => plan.base
      end

      def modified
        plan = ServicePlan.find(params.require(:service_plan_id))

        if plan.modified.present?
          render :json => plan.modified
        else
          head :no_content
        end
      end

      def update_modified
        plan = ServicePlan.find(params.require(:service_plan_id))
        plan.update!(:modified => params.require(:modified))

        render :json => plan.modified
      end
    end
  end
end
