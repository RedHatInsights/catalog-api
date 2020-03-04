module Api
  module V1
    class TagsController < ApplicationController
      include Api::V1::Mixins::IndexMixin
      include Insights::API::Common::TaggingMethods

      def index
        if params[:portfolio_id]
          scope = Portfolio.where(:id => params.require(:portfolio_id))
          relevant_portfolio = policy_scope(scope, :policy_scope_class => PortfolioPolicy::Scope).first
          relevant_tags = relevant_portfolio.try(:tags) || Tag.none

          collection(relevant_tags, :pre_authorized => true)
        elsif params[:portfolio_item_id]
          scope = PortfolioItem.where(:id => params.require(:portfolio_item_id))
          relevant_portfolio_item = policy_scope(scope, :policy_scope_class => PortfolioItemPolicy::Scope).first
          relevant_tags = relevant_portfolio_item.try(:tags) || Tag.none

          collection(relevant_tags, :pre_authorized => true)
        else
          collection(Tag.all)
        end
      end

      def show
        tag = Tag.find(params.require(:id))

        render :json => tag
      end

      private

      def instance_link(instance)
        endpoint = instance.class.name.underscore
        version  = self.class.send(:api_version)
        send("api_#{version}_#{endpoint}_url", instance.id)
      end
    end
  end
end
