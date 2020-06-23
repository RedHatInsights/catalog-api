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
    end
  end
end
