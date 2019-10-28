module Api
  module V1
    class TagsController < ApplicationController
      include Api::V1::Mixins::IndexMixin

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
    end
  end
end
