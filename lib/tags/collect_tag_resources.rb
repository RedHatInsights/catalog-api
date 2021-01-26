module Tags
  class CollectTagResources
    attr_reader :tag_resources

    def initialize(task, order)
      @task = task
      @order = order
    end

    def process
      @tag_resources = local_tag_resources + remote_tag_resources
      Rails.logger.info("Tag resources for order #{@order.id}: #{@tag_resources}")

      self
    end

    private

    def local_tag_resources
      @local_tag_resources = CollectLocalOrderResources.new(:order_id => @order.id).process.tag_resources
    end

    def remote_tag_resources
      @remote_tag_resources = Inventory::RemoteInventory.new(@task).process.tag_resources
    end
  end
end
