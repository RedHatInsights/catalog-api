module Tags
  module CatalogInventory
    class RemoteInventory
      attr_reader :tag_resources

      def initialize(order_item)
        @item = order_item
      end

      def process
        consolidate_inventory_tags

        Rails.logger.info("Remote Tags #{@tag_resources}")
        self
      end

      private

      def consolidate_inventory_tags
        tags = all_tag_collections.collect do |tag|
          {:tag => tag.tag}
        end

        @tag_resources = [{
          :app_name    => "catalog-inventory",
          :object_type => "ServiceInventory",
          :tags        => tags
        }]
      end

      def all_tag_collections
        result = []
        ::CatalogInventory::Service.call(::CatalogInventoryApiClient::ServiceOfferingApi) do |api|
          result = api.applied_inventories_tags_for_service_offering(service_offering_id, ::CatalogInventoryApiClient::AppliedInventoriesParametersServicePlan.new)
        end
        Rails.logger.info(" Applied Tags #{result}")
        result
      end

      def service_offering_id
        @item.portfolio_item.service_offering_ref.to_s
      end
    end
  end
end
