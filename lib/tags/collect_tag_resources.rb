module Tags
  class CollectTagResources
    attr_reader :tag_resources

    def initialize(order_item)
      @item = order_item
    end

    def process
      @tag_resources = local_tag_resources + remote_tag_resources
      Rails.logger.info("Tag resources for order #{@item.order.id}: #{@tag_resources}")

      self
    end

    private

    def local_tag_resources
      @local_tag_resources = CollectLocalOrderResources.new(:order_id => @item.order.id).process.tag_resources
    end

    def remote_tag_resources
      @remote_tag_resources = ::Tags::CatalogInventory::RemoteInventory.new(@item).process.tag_resources
    end
  end
end
