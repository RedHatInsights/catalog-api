module Api
  module V1x2
    class IconsController < Api::V1x1::IconsController
      private

      def parse_raw_icon_params
        params.permit(:icon_id, :portfolio_item_id, :portfolio_id, :cache_id)
      end
    end
  end
end
