module Catalog
  class DetermineTaskRelevancy
    def initialize(topic)
      @topic = topic
    end

    def process
      @task = TopologicalInventory.call do |api|
        api.show_task(@topic.payload["task_id"])
      end

      if @task.context.has_key_path?(:service_instance, :id)
        Catalog::UpdateOrderItem.new(@topic, @task).process
      elsif @task.context.has_key_path?(:applied_inventories)
        Catalog::CreateApprovalRequest.new(@task).process
      end

      self
    end
  end
end
