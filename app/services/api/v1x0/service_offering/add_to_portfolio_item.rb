module Api
  module V1x0
    module ServiceOffering
      class AddToPortfolioItem
        include SourceMixin
        IGNORE_FIELDS = %w[id created_at updated_at portfolio_id tenant_id].freeze

        attr_reader :item

        def initialize(params)
          @params = HashWithIndifferentAccess.new(params)
        end

        def process
          # Get the api response object from Topology
          TopologicalInventory.call do |api_instance|
            @service_offering = api_instance.show_service_offering(@params[:service_offering_ref])
          end

          raise Catalog::NotAuthorized unless valid_source?(@service_offering.source_id)

          # Get the fields that we're going to pull over
          @item = PortfolioItem.create!(generate_attributes)

          icon = create_icon(@service_offering.service_offering_icon_id) if @service_offering.service_offering_icon_id.present?
          @item.icon = icon unless icon.nil?

          self
        rescue StandardError => e
          Rails.logger.error("Service Offering Ref: #{@params[:service_offering_ref]} #{e.message}")
          raise
        end

        private

        def creation_fields
          service_offering_columns = @service_offering.instance_variables.map { |x| x.to_s[1..-1] }
          portfolio_item_columns = PortfolioItem.column_names - IGNORE_FIELDS
          service_offering_columns & portfolio_item_columns
        end

        def generate_attributes
          creation_fields.each do |column|
            @params[column] ||= @service_offering.send(column) if @service_offering.send(column).present?
          end
          populate_missing_fields
        end

        # If certain fields are empty populate them from the other fields that we do have.
        def populate_missing_fields
          @params[:service_offering_type] = @service_offering.extra[:type] if @service_offering.extra
          @params[:service_offering_source_ref] = @service_offering.source_id
          @params
        end

        def create_icon(icon_id)
          service_offering_icon = TopologicalInventory.call { |topo| topo.show_service_offering_icon(icon_id) }
          return if service_offering_icon.data.nil?

          file = Tempfile.new('service_offering').tap do |fh|
            fh.write(service_offering_icon.data)
            fh.rewind
          end

          svc = Catalog::CreateIcon.new(
            :content           => OpenStruct.new(:tempfile => file),
            :source_ref        => service_offering_icon.source_ref,
            :source_id         => service_offering_icon.source_id,
            :portfolio_item_id => @item.id
          )

          svc.process.icon
        end
      end
    end
  end
end
