module Api
  module V1
    class PortfoliosController < ApplicationController
      include Api::V1::Mixins::IndexMixin
      include Api::V1::Mixins::ValidationMixin
      include Api::V1::Mixins::TagsMixin

      before_action :update_access_check, :only => %i[add_portfolio_item_to_portfolio update create_tags]
      before_action :create_access_check, :only => %i[create]
      before_action :delete_access_check, :only => %i[destroy]
      before_action :read_access_check, :only => %i[show]

      before_action :only => %i[copy] do
        resource_check('read', params.require(:portfolio_id))
        permission_check('create')
        permission_check('update')
      end

      def index
        if params[:tag_id]
          collection(Tag.find(params.require(:tag_id)).portfolios)
        else
          collection(Portfolio.all)
        end
      end

      def add_portfolio_item_to_portfolio
        portfolio = Portfolio.find(params.require(:portfolio_id))
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))
        render :json => portfolio.add_portfolio_item(portfolio_item)
      end

      def create
        portfolio = Portfolio.create!(params_for_create)
        render :json => portfolio
      end

      def update
        portfolio = Portfolio.find(params.require(:id))
        portfolio.update!(params_for_update)

        render :json => portfolio
      end

      def show
        portfolio = Portfolio.find(params.require(:id))

        render :json => portfolio
      end

      def destroy
        portfolio = Portfolio.find(params.require(:id))
        svc = Catalog::SoftDelete.new(portfolio)
        key = svc.process.restore_key

        render :json => { :restore_key => key }
      end

      def restore
        portfolio = Portfolio.with_discarded.discarded.find(params.require(:portfolio_id))
        Catalog::SoftDeleteRestore.new(portfolio, params.require(:restore_key)).process

        render :json => portfolio
      end

      def share
        portfolio = Portfolio.find(params.require(:portfolio_id))
        options = {:app_name      => ENV['APP_NAME'],
                   :resource_name => 'portfolios',
                   :resource_ids  => [portfolio.id.to_s],
                   :permissions   => params[:permissions],
                   :group_uuids   => params.require(:group_uuids)}
        Insights::API::Common::RBAC::ShareResource.new(options).process
        head :no_content
      end

      def unshare
        portfolio = Portfolio.find(params.require(:portfolio_id))
        options = {:app_name      => ENV['APP_NAME'],
                   :resource_name => 'portfolios',
                   :resource_ids  => [portfolio.id.to_s],
                   :permissions   => params[:permissions],
                   :group_uuids   => params[:group_uuids] || []}
        Insights::API::Common::RBAC::UnshareResource.new(options).process
        head :no_content
      end

      def share_info
        portfolio = Portfolio.find(params.require(:portfolio_id))
        options = {:app_name      => ENV['APP_NAME'],
                   :resource_name => 'portfolios',
                   :resource_id   => portfolio.id.to_s}
        obj = Insights::API::Common::RBAC::QuerySharedResource.new(options).process
        render :json => obj.share_info
      end

      def copy
        svc = Catalog::CopyPortfolio.new(portfolio_copy_params)
        render :json => svc.process.new_portfolio
      end


      private

      def portfolio_copy_params
        params.permit(:portfolio_id, :portfolio_name)
      end
    end
  end
end
