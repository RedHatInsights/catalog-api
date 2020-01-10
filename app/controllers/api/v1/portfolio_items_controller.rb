module Api
  module V1
    class PortfolioItemsController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      before_action :create_access_check, :only => %i[create] do
        # TODO: Busted need the caller to pass in the portfolio id
        # parent_check(:portfolio, 'update')
        permission_check('create', Portfolio)
      end
      before_action :update_access_check, :only => %i[update] do
        parent_check(:portfolio, 'update')
      end
      before_action :delete_access_check, :only => %i[destroy] do
        parent_check(:portfolio, 'delete')
      end

      before_action :only => [:copy] do
        parent_check(:portfolio, 'read', params.require(:portfolio_item_id))
        permission_check('create', Portfolio)
        permission_check('update', Portfolio)
      end

      def index
        if params[:portfolio_id]
          collection(Portfolio.find(params.require(:portfolio_id)).portfolio_items)
        elsif params[:tag_id]
          collection(Tag.find(params.require(:tag_id)).portfolio_items)
        else
          collection(PortfolioItem.all)
        end
      end

      def create
        so = ServiceOffering::AddToPortfolioItem.new(params_for_create)
        render :json => so.process.item
      end

      def update
        portfolio_item = PortfolioItem.find(params.require(:id))
        portfolio_item.update!(params_for_update)

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

      private

      def portfolio_copy_params
        params.permit(:portfolio_item_id, :portfolio_id, :portfolio_item_name)
      end
    end
  end
end
