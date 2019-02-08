module Api
  module V0x1
    class IconController < ApplicationController
      include Api::V0x1::Mixins::IndexMixin

      def index
        portfolio_item = PortfolioItem.find(params.require(:portfolio_item_id))
        so = ServiceOffering::Icons.new(portfolio_item.service_offering_icon_ref)
        render :json => so.process.icon
      rescue ActiveRecord::RecordNotFound => e
        render :json => { :message => e.message }, :status => :not_found
      rescue ArgumentError
        render :json => { :message => "Icon ID not present on Portfolio Item" }, :status => :not_found
      end
    end
  end
end
