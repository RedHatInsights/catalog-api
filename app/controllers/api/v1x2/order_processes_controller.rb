module Api
  module V1x2
    class OrderProcessesController < ApplicationController
      include Mixins::IndexMixin
      include Mixins::ShowMixin

      def index
        relation = for_resource_object? ? Catalog::GetLinkedOrderProcess.new(params).process.order_processes : OrderProcess.all

        collection(relation)
      end

      def create
        order_process = authorize(OrderProcess.new(writeable_params_for_create))
        order_process.save!

        render :json => order_process
      end

      def link
        order_process = OrderProcess.find(params.require(:id))
        authorize(order_process)

        Catalog::LinkToOrderProcess.new(params).process

        head :no_content
      end

      def unlink
        order_process = OrderProcess.find(params.require(:id))
        authorize(order_process)

        Catalog::UnlinkFromOrderProcess.new(params).process

        head :no_content
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

      def update_before_portfolio_item
        order_process = update_association(:before_portfolio_item)

        render :json => order_process
      end

      def update_after_portfolio_item
        order_process = update_association(:after_portfolio_item)

        render :json => order_process
      end

      def update_return_portfolio_item
        order_process = update_association(:return_portfolio_item)

        render :json => order_process
      end

      def remove_association
        order_process = OrderProcess.find(params.require(:order_process_id))
        authorize(order_process, :update?)

        order_process = Catalog::OrderProcessDissociator.new(
          order_process,
          params.require(:associations_to_remove)
        ).process.order_process

        render :json => order_process
      end

      private

      def update_association(association)
        order_process = OrderProcess.find(params.require(:order_process_id))
        authorize(order_process, "update?")

        Catalog::OrderProcessAssociator.new(
          order_process, params.require(:portfolio_item_id), association
        ).process.order_process
      end

      def for_resource_object?
        raise ::Catalog::InvalidParameter, "Invalid resource object params: #{resource_params}" unless resource_params.length.zero? || resource_params.length == 3

        !!(resource_params[:app_name] && resource_params[:object_id] && resource_params[:object_type])
      end

      def resource_params
        @resource_params ||= params.slice(:object_type, :object_id, :app_name).to_unsafe_h
      end
    end
  end
end
