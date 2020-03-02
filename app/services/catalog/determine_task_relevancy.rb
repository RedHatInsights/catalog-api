module Catalog
  class DetermineTaskRelevancy
    def initialize(topic)
      @topic = topic
    end

    def process
      @task = TopologicalInventoryApiClient::Task.new(
        :id      => @topic.payload["task_id"],
        :state   => @topic.payload["state"],
        :status  => @topic.payload["status"],
        :context => @topic.payload["context"].try(&:with_indifferent_access)
      )

      add_task_update_message
      delegate_task if @task.state == "completed"
      fail_order if @task.status == "error"

      self
    rescue StandardError => exception
      Rails.logger.error(exception.inspect)
      raise
    end

    private

    def delegate_task
      if @task.context.has_key_path?(:service_instance, :id)
        Catalog::UpdateOrderItem.new(@topic, @task).process
      elsif @task.context.has_key_path?(:applied_inventories)
        Rails.logger.info("Creating approval request for task")
        Catalog::CreateApprovalRequest.new(@task).process
      else
        Rails.logger.info("Incoming task has no current relevant delegation")
      end
    end

    def order_item
      @order_item ||= OrderItem.find_by!(:topology_task_ref => @topic.payload["task_id"])
    end

    def add_task_update_message
      message = "Task update. State: #{@task.state}. Status: #{@task.status}. Context: #{@task.context}"
      @task.status == "error" ? add_update_message(:error, message) : add_update_message(:info, message)
    end

    def add_update_message(state, message)
      order_item.update_message(state, message)
      Rails.logger.send(state, message)
    end

    def fail_order
      order_item.update!(:state => "Failed")
      Catalog::OrderStateTransition.new(order_item.order_id).process
    end
  end
end
