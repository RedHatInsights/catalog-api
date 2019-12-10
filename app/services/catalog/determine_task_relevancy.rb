module Catalog
  class DetermineTaskRelevancy
    def initialize(topic)
      @topic = topic
    end

    def process
      Rails.logger.info("Looking for task in topology with topic: #{@topic}")

      sleep 5
      @task = TopologicalInventory.call do |api|
        api.show_task(@topic.payload["task_id"])
      end

      Rails.logger.info("Found task: #{@task}")

      if @task.context.has_key_path?(:service_instance, :id)
        Catalog::UpdateOrderItem.new(@topic, @task).process
      elsif @task.context.has_key_path?(:applied_inventories)
        Rails.logger.info("Creating approval request for task")
        Catalog::CreateApprovalRequest.new(@task).process
      else
        item = OrderItem.find_by!(:topology_task_ref => @task.id)
        item.update_message(:error, "Topology task error")
        Rails.logger.error(
          "Topology error during task. State: #{@task.state}. Status: #{@task.status}. Context: #{@task.context}"
        )
      end

      self
    end
  end
end
