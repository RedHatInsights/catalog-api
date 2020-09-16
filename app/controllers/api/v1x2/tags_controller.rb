module Api
  module V1x2
    class TagsController < Api::V1x1::TagsController
      def index
        if params[:portfolio_id]
          scope = Portfolio.where(:id => params.require(:portfolio_id))
          relevant_portfolio = policy_scope(scope, :policy_scope_class => PortfolioPolicy::Scope).first
          raise ActiveRecord::RecordNotFound unless relevant_portfolio

          relevant_tags = relevant_portfolio.tags || Tag.none

          collection(relevant_tags, :pre_authorized => true)
        elsif params[:portfolio_item_id]
          scope = PortfolioItem.where(:id => params.require(:portfolio_item_id))
          relevant_portfolio_item = policy_scope(scope, :policy_scope_class => PortfolioItemPolicy::Scope).first
          raise ActiveRecord::RecordNotFound unless relevant_portfolio_item

          relevant_tags = relevant_portfolio_item.tags || Tag.none

          collection(relevant_tags, :pre_authorized => true)
        elsif params[:order_process_id]
          scope = OrderProcess.where(:id => params.require(:order_process_id))
          relevant_order_process = policy_scope(scope, :policy_scope_class => OrderProcessPolicy::Scope).first
          raise ActiveRecord::RecordNotFound unless relevant_order_process

          relevant_tags = relevant_order_process.tags || Tag.none

          collection(relevant_tags, :pre_authorized => true)
        else
          collection(Tag.all)
        end
      end
    end
  end
end
