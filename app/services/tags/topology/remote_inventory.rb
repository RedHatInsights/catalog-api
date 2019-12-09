module Tags
  module Topology
    class RemoteInventory
      attr_reader :tag_resources

      def initialize(task)
        @task = task
      end

      def process
        consolidate_inventory_tags

        self
      end

      private

      def consolidate_inventory_tags
        # This is meant to bypass the heavy logic but also assign an empty array
        # It appears to return "true" but the #process method returns self so I
        # only needed this for assignment and bypass purposes in one line
        return @tag_resources = [] if @task.nil?

        @tag_resources = all_tag_collections.collect do |tag_collection|
          tags = tag_collection.collect do |tag|
            tag.to_hash.slice(:name, :namespace, :value)
          end

          {
            :app_name    => "topology",
            :object_type => "ServiceInventory",
            :tags        => tags
          }
        end
      end

      def all_tag_collections
        @task.context[:applied_inventories].collect do |inventory_id|
          TopologicalInventory.call do |api|
            api.list_service_inventory_tags(inventory_id).data
          end
        end
      end
    end
  end
end
