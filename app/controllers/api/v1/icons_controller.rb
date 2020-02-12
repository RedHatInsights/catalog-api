module Api
  module V1
    class IconsController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      # Due to the fact form-data is getting uploaded and isn't supported by openapi_parser
      skip_before_action :validate_request, :only => %i[create update]

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
        image = find_icon(params.permit(:icon_id, :portfolio_item_id, :portfolio_id)).image.decoded_image
        send_data(image,
                  :type        => MimeMagic.by_magic(image).type,
                  :disposition => 'inline')
      rescue ActiveRecord::RecordNotFound
        Rails.logger.debug("Icon not found for params: #{params.keys.select { |key| key.end_with?("_id") }}")
        head :no_content
      end

      private

      def icon_params
        params.require(:content)
        icon_patch_params
      end

      def icon_patch_params
        params.permit(:content, :source_ref, :source_id, :portfolio_item_id, :portfolio_id, :id)
      end

      def find_icon(ids)
        if ids[:portfolio_item_id].present?
          Icon.find_by!(:restore_to => PortfolioItem.find(ids[:portfolio_item_id]))
        elsif ids[:portfolio_id].present?
          Icon.find_by!(:restore_to => Portfolio.find(ids[:portfolio_id]))
        end
      end
    end
  end
end
