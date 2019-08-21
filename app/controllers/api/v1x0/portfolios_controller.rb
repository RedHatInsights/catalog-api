module Api
  module V1x0
    class PortfoliosController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      before_action :write_access_check, :only => %i(add_portfolio_item_to_portfolio create update destroy)
      before_action :read_access_check, :only => %i(show)
      before_action :only => %i[share unshare] do
        permission_array_check(params.require(:permissions))
        permission_format_check(params.require(:permissions))
        group_id_array_check(params.require(:group_uuids))
      end

      before_action :only => %i[copy] do
        resource_check('read', params.require(:portfolio_id))
        permission_check('write')
      end

      def index
        collection(Portfolio.all)
      end

      def add_portfolio_item_to_portfolio
        portfolio = Portfolio.find(params.require(:portfolio_id))
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))
        render :json => portfolio.add_portfolio_item(portfolio_item)
      end

      def create
        portfolio = Portfolio.create!(portfolio_params)
        render :json => portfolio
      rescue ActiveRecord::RecordInvalid => e
        render :json => { :errors => e.message }, :status => :unprocessable_entity
      end

      def update
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
        RBAC::ShareResource.new(options).process
        head :no_content
      end

      def unshare
        portfolio = Portfolio.find(params.require(:portfolio_id))
        options = {:app_name      => ENV['APP_NAME'],
                   :resource_name => 'portfolios',
                   :resource_ids  => [portfolio.id.to_s],
                   :permissions   => params[:permissions],
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

      def copy
        svc = Catalog::CopyPortfolio.new(portfolio_copy_params)
        render :json => svc.process.new_portfolio
      end

      private

      def portfolio_params
        params.permit(:name, :description, :image_url, :enabled, :workflow_ref)
      end

      def portfolio_copy_params
        params.permit(:portfolio_id, :portfolio_name)
      end

      def group_id_array_check(uuids)
        if !uuids.kind_of?(Array)
          invalid_parameter('Group should be an array')
        elsif uuids.blank? || uuids.any?(&:blank?)
          invalid_parameter('Group should not be empty')
        end
      end
    end
  end
end
