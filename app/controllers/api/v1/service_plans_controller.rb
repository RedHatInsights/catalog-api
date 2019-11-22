module Api
  module V1
    class ServicePlansController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      def index
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))

        if portfolio_item.service_plans.empty?
          render :json => Catalog::ServicePlans.new(portfolio_item.id).process.items
        else
          render :json => Catalog::ServicePlanJson.new(:portfolio_item_id => portfolio_item.id, :collection => true).process.json
        end
      end

      def create
        svc = Catalog::ImportServicePlans.new(params.require(:portfolio_item_id))
        render :json => svc.process.service_plans
      end

      def show
        svc = Catalog::ServicePlanJson.new(:service_plan_id => params.require(:id))
        render :json => svc.process.json
      end

      def base
        svc = Catalog::ServicePlanJson.new(:service_plan_id => params.require(:service_plan_id), :schema => "base")
        render :json => svc.process.json
      end

      def modified
        plan = Catalog::ServicePlanJson.new(:service_plan_id => params.require(:service_plan_id)).process.json

        if plan["create_json_schema"]
          render :json => plan
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
