module Api
  module V1
    class TagsController < ApplicationController
      include Api::V1::Mixins::IndexMixin
      include Insights::API::Common::TaggingMethods

      def index
        if params[:portfolio_id]
          collection(Portfolio.find(params.require(:portfolio_id)).tags)
        elsif params[:portfolio_item_id]
          collection(PortfolioItem.find(params.require(:portfolio_item_id)).tags)
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
