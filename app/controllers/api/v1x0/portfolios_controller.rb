module Api
  module V1x0
    class PortfoliosController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin
      include Api::V1x0::Mixins::RBACMixin

      def index
        collection(Portfolio.all)
      end

      def add_portfolio_item_to_portfolio
        write_access_check
        portfolio = Portfolio.find(params.require(:portfolio_id))
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))
        render :json => portfolio.add_portfolio_item(portfolio_item)
      end

      def create
        write_access_check
        portfolio = Portfolio.create!(portfolio_params)
        render :json => portfolio
      rescue ActiveRecord::RecordInvalid => e
        render :json => { :errors => e.message }, :status => :unprocessable_entity
      end

      def update
        write_access_check
        portfolio = Portfolio.find(params.require(:id))
        portfolio.update!(portfolio_params)

        render :json => portfolio
      end

      def show
        portfolio = Portfolio.find(params.require(:id))
        portfolio.update!(portfolio_params)

        render :json => portfolio
      end

      def destroy
        write_access_check
        portfolio = Portfolio.find(params.require(:id))
        if portfolio.discard
          head :no_content
        else
          render :json => { :errors => portfolio.errors }, :status => :unprocessable_entity
        end
      end

      def share
        portfolio = Portfolio.find(params.require(:portfolio_id))
        options = {:app_name      => ENV['APP_NAME'],
                   :resource_name => 'portfolios',
                   :resource_ids  => [portfolio.id.to_s],
                   :permissions   => params.require(:permissions),
                   :group_uuids   => params.require(:group_uuids)}
        RBAC::ShareResource.new(options).process
        head :no_content
      end

      def unshare
        portfolio = Portfolio.find(params.require(:portfolio_id))
        options = {:app_name      => ENV['APP_NAME'],
                   :resource_name => 'portfolios',
                   :resource_ids  => [portfolio.id.to_s],
                   :permissions   => params.require(:permissions),
                   :group_uuids   => params[:group_uuids] || []}
        RBAC::UnshareResource.new(options).process
        head :no_content
      end

      def share_info
        portfolio = Portfolio.find(params.require(:portfolio_id))
        options = {:app_name      => ENV['APP_NAME'],
                   :resource_name => 'portfolios',
                   :resource_id   => portfolio.id.to_s}
        obj = RBAC::QuerySharedResource.new(options).process
        render :json => obj.share_info
      end

      private

      def portfolio_params
        params.permit(:name, :description, :image_url, :enabled, :workflow_ref)
      end
    end
  end
end
