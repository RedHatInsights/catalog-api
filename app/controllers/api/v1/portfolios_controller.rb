module Api
  module V1
    class PortfoliosController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      def index
        if params[:tag_id]
          collection(Tag.find(params.require(:tag_id)).portfolios)
        else
          collection(Portfolio.all)
        end
      end

      def create
        authorize(Portfolio)

        portfolio = Portfolio.create!(writeable_params_for_create)
        render :json => portfolio
      end

      def update
        portfolio = Portfolio.find(params.require(:id))
        authorize(portfolio)

        portfolio.update!(params_for_update)

        render :json => portfolio
      end

      def show
        portfolio = Portfolio.find(params.require(:id))
        authorize(portfolio)

        render :json => portfolio
      end

      def destroy
        portfolio = Portfolio.find(params.require(:id))
        authorize(portfolio)

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
        authorize(portfolio, :share_or_unshare?)
        options = {:object      => portfolio,
                   :permissions => params[:permissions],
                   :group_uuids => params.require(:group_uuids)}
        Catalog::ShareResource.new(options).process
        head :no_content
      end

      def unshare
        portfolio = Portfolio.find(params.require(:portfolio_id))
        authorize(portfolio, :share_or_unshare?)
        options = {:object      => portfolio,
                   :permissions => params[:permissions],
                   :group_uuids => params.require(:group_uuids)}
        Catalog::UnshareResource.new(options).process
        head :no_content
      end

      def share_info
        portfolio = Portfolio.find(params.require(:portfolio_id))
        options = {:object => portfolio}
        render :json => Catalog::ShareInfo.new(options).process.result
      end

      def copy
        portfolio = Portfolio.find(params.require(:portfolio_id))
        authorize(portfolio)

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
