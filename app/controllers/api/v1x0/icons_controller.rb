module Api
  module V1x0
    class IconsController < ApplicationController
      include Api::V1x0::Mixins::IndexMixin

      def show
        if params[:portfolio_item_id].present?
          portfolio_item = PortfolioItem.find_by!(:id => params.require(:portfolio_item_id))
          raise ActiveRecord::RecordNotFound, "Icon not present on Portfolio Item" if portfolio_item.service_offering_icon_ref.nil?
          send_icon_data(portfolio_item.service_offering_icon_ref)
        else
          send_icon_data(params.require(:id))
        end
      rescue ActiveRecord::RecordNotFound => e
        render :json => { :message => e.message }, :status => :not_found
      end

      def icon_bulk_query
        render :json => get_all_icons(params.require(:ids))
      rescue Catalog::TopologyError => e
        render :json => { :message => e.message }, :status => :not_found
      end

      private

      def send_icon_data(id)
        so = ServiceOffering::Icons.new(id)
        icon = so.process.icon
        send_data(icon.data,
                  :type        => MimeMagic.by_magic(icon.data).type,
                  :disposition => 'inline')
      end

      def get_all_icons(ids)
        ids.split(",").uniq.each_with_object([]) do |id, results|
          results << ServiceOffering::Icons.new(id).process.icon
        end
      end
    end
  end
end
