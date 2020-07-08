module Api
  module V1x0
    class PortfolioItemsController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::ShowMixin

      def index
        if params[:portfolio_id]
          collection(Portfolio.find(params.require(:portfolio_id)).portfolio_items)
        else
          authorize(PortfolioItem)
          collection(PortfolioItem.all)
        end
      end

      def create
        portfolio = Portfolio.find(params.require(:portfolio_id))
        authorize(portfolio, :policy_class => PortfolioItemPolicy)

        so = ServiceOffering::AddToPortfolioItem.new(writeable_params_for_create)
        render :json => so.process.item
      end

      def update
        portfolio_item = PortfolioItem.find(params.require(:id))
        authorize(portfolio_item)

        portfolio_item.update!(params_for_update)

        render :json => portfolio_item
      end

      def destroy
        item = PortfolioItem.find(params.require(:id))
        authorize(item)

        soft_delete = Catalog::SoftDelete.new(item)

        render :json => { :restore_key => soft_delete.process.restore_key }
      end

      def copy
        portfolio_item = PortfolioItem.find(params[:portfolio_item_id])
        authorize(portfolio_item)

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
