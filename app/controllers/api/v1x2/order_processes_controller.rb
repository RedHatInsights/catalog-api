module Api
  module V1x2
    class OrderProcessesController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::ShowMixin

      def index
        collection(OrderProcess.all)
      end

      def create
        order_process = authorize(OrderProcess.new(writeable_params_for_create))
        order_process.save!

        render :json => order_process
      end

      def update
        order_process = OrderProcess.find(params.require(:id))
        authorize(order_process)

        order_process.update!(params_for_update)

        render :json => order_process
      end

      def destroy
        order_process = OrderProcess.find(params.require(:id))
        authorize(order_process)

        order_process.destroy!

        head :no_content
      end

      def update_pre
        order_process = OrderProcess.find(params.require(:order_process_id))
        authorize(order_process, :update?)

        pre_portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))
        order_process.update!(:pre => pre_portfolio_item)

        render :json => order_process
      end
    end
  end
end
