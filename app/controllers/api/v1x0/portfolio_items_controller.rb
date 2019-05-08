module Api
  module V1x0
    class PortfolioItemsController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      before_action :write_access_check, :only => %i[create update destroy]

      before_action :only => [:copy] do
        resource_check('read', params.require(:portfolio_item_id))
        permission_check('write', Portfolio)
      end

      def index
        if params[:portfolio_id]
          collection(Portfolio.find(params.require(:portfolio_id)).portfolio_items)
        else
          collection(PortfolioItem.all)
        end
      end

      def create
        so = ServiceOffering::AddToPortfolioItem.new(portfolio_item_params)
        render :json => so.process.item
      rescue Catalog::TopologyError => e
        render :json => { :errors => e.message }, :status => :not_found
      end

      def update
        portfolio_item = PortfolioItem.find(params.require(:id))
        portfolio_item.update!(portfolio_item_patch_params)

        render :json => portfolio_item
      end

      def show
        render :json => PortfolioItem.find(params.require(:id))
      end

      def destroy
        PortfolioItem.find(params.require(:id)).discard
        head :no_content
      end

      def copy
        svc = Catalog::CopyPortfolioItem.new(portfolio_copy_params)
        render :json => svc.process.new_portfolio_item
      rescue ActiveRecord::RecordNotFound => e
        json_response({ :errors => e.message }, :unprocessable_entity)
      end

      private

      def portfolio_item_params
        params.require(:service_offering_ref)
        params.permit(:service_offering_ref, :workflow_ref)
      end

      def portfolio_item_patch_params
        params.permit(:favorite, :name, :description, :orphan, :state, :display_name, :long_description, :distributor, :documentation_url, :support_url, :workflow_ref)
      end

      def portfolio_copy_params
        params.permit(:portfolio_item_id, :portfolio_id)
      end
    end
  end
end
