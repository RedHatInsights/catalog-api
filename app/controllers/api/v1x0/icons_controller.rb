module Api
  module V1x0
    class IconsController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      def show
        portfolio_item = PortfolioItem.find_by!(:id => params.require(:portfolio_item_id))
        raise ActiveRecord::RecordNotFound, "Icon not present on Portfolio Item" if portfolio_item.service_offering_icon_ref.nil?

        so = ServiceOffering::Icons.new(portfolio_item.service_offering_icon_ref)
        icon = so.process.icon

        send_data(icon.data,
                  :type        => MimeMagic.by_magic(icon.data).type,
                  :disposition => 'inline')
      rescue ActiveRecord::RecordNotFound, Catalog::TopologyError => e
        render :json => { :message => e.message }, :status => :not_found
      end
    end
  end
end
