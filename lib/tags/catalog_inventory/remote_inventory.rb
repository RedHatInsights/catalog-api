module Tags
  module CatalogInventory
    class RemoteInventory
      attr_reader :tag_resources

      def initialize(order_item)
        @item = order_item
      end

      def process
        consolidate_inventory_tags

        self
      end

      private

      def consolidate_inventory_tags
        @tag_resources = all_tag_collections.collect do |tag_collection|
          tags = tag_collection.collect do |tag|
            {:tag => tag.tag}
          end

          {
            :app_name    => "catalog-inventory",
            :object_type => "ServiceInventory",
            :tags        => tags
          }
        end
      end

      def all_tag_collections
        ::CatalogInventory::Service.call(CatalogInventoryApiClient::ServiceOfferingApi) do |api|
          api.applied_inventories_tags_for_service_offering(service_offering_id, CatalogInventoryApiClient::AppliedInventoriesParametersServicePlan.new).data
        end
      end

      def service_offering_id
        @item.portfolio_item.service_offering_ref.to_s
      end
    end
  end
end
