module Api
  module V1x0
    class IconsController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      def show
        render :json => Icon.find(params.require(:id))
      end

      def create
        icon = Icon.create!(icon_params)
        render :json => icon
      end

      def destroy
        Icon.find(params.require(:id)).destroy
        head :no_content
      end

      def update
        icon = Icon.find(params.require(:id))
        icon.update!(icon_patch_params)

        render :json => icon
      end

      def show_icon
        icon = find_icon
        send_data(icon.data,
                  :type        => MimeMagic.by_magic(icon.data).type,
                  :disposition => 'inline')
      end

      private

      def icon_params
        params.require(:data)
        icon_patch_params
      end

      def icon_patch_params
        params.permit(:data, :source_ref, :source_id, :portfolio_item_id)
      end

      def find_icon
        params[:icon_id].present? ? Icon.find(params[:icon_id]) : Icon.find_by!(:portfolio_item_id => params[:portfolio_item_id])
      end
    end
  end
end
