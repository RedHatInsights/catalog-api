module Api
  module V1
    class PortfolioItemsController < ApplicationController
      include Api::V1::Mixins::IndexMixin

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
        item = PortfolioItem.find(params.require(:id))
        soft_delete = Catalog::SoftDelete.new(item)

        render :json => { :restore_key => soft_delete.process.restore_key }
      end

      def copy
        svc = Catalog::CopyPortfolioItem.new(portfolio_copy_params)
        render :json => svc.process.new_portfolio_item
      end

      def undestroy
        item = PortfolioItem.with_discarded.discarded.find(params.require(:portfolio_item_id))
        Catalog::SoftDeleteRestore.new(item, params.require(:restore_key)).process

        render :json => item
      end

      def next_name
        svc = Catalog::NextName.new(params.require(:portfolio_item_id), params[:destination_portfolio_id])
        render :json => { :next_name => svc.process.next_name }
      end

      def add_icon_to_portfolio_item
        icon = Icon.find(params.require(:icon_id))
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))
        render :json => portfolio_item.icons << icon
      end

      private

      def portfolio_item_params
        params.require(:service_offering_ref)
        params.permit(:service_offering_ref, :workflow_ref)
      end

      def portfolio_item_patch_params
        params.permit(:favorite, :name, :description, :orphan, :state, :display_name, :long_description, :distributor, :documentation_url, :support_url, :workflow_ref, :id, :service_offering_source_ref)
      end

      def portfolio_copy_params
        params.permit(:portfolio_item_id, :portfolio_id, :portfolio_item_name)
      end
    end
  end
end
