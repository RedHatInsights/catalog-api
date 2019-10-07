module Api
  module V1
    class IconsController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      # Due to the fact form-data is getting uploaded and isn't supported by openapi_parser
      skip_before_action :validate_request, :only => %i[create update]

      def show
        render :json => Icon.find(params.require(:id))
      end

      def create
        icon = Catalog::CreateIcon.new(icon_params).process.icon
        render :json => icon
      end

      def destroy
        Catalog::SoftDelete.new(Icon.find(params.require(:id))).process
        head :no_content
      end

      def update
        icon = Catalog::UpdateIcon.new(params.require(:id), icon_patch_params).process.icon
        render :json => icon
      end

      def raw_icon
        image = find_icon(params.permit(:icon_id, :portfolio_item_id)).image.decoded_image
        send_data(image,
                  :type        => MimeMagic.by_magic(image).type,
                  :disposition => 'inline')
      rescue ActiveRecord::RecordNotFound
        Rails.logger.debug("Icon not found for params: #{params.keys.select { |key| key.end_with?("_id") }}")
        head :no_content
      end

      def override_icon
        overriden_icon = Catalog::OverrideIcon.new(params.require(:icon_id), params.require(:portfolio_item_id))
        render :json => overriden_icon.process.icon
      end

      private

      def icon_params
        params.require([:content, :portfolio_item_id])
        icon_patch_params
      end

      def icon_patch_params
        params.permit(:content, :source_ref, :source_id, :portfolio_item_id, :id)
      end

      def find_icon(ids)
        ids[:icon_id].present? ? Icon.find(ids[:icon_id]) : Icon.find_by!(:portfolio_item_id => ids[:portfolio_item_id])
      end
    end
  end
end
