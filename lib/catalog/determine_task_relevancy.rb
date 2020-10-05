module Catalog
  class DetermineTaskRelevancy
    def initialize(topic)
      @topic = topic
    end

    def process
      @task = TopologicalInventoryApiClient::Task.new(
        :id      => @topic.payload["task_id"].to_s,
        :state   => @topic.payload["state"],
        :status  => @topic.payload["status"],
        :context => @topic.payload["context"].try(&:with_indifferent_access)
      )

      find_relevant_order_item
      delegate_task

      self
    rescue ActiveRecord::RecordNotFound
      Rails.logger.info("Incoming task #{@task.id} has no relevant order item")
      self
    rescue => exception
      Rails.logger.error(exception.inspect)
      raise
    end

    private

    def delegate_task
      if @task.status == "error"
        process_error_tasks
      else
        # Status is either 'warn' or 'ok'
        process_relevant_context
      end
    end

    def process_relevant_context
      if @task.context&.has_key_path?(:service_instance)
        UpdateOrderItem.new(@task, @order_item).process
      elsif @task.context&.has_key_path?(:applied_inventories)
        Rails.logger.info("Creating approval request for task id #{@task.id}")
        CreateApprovalRequest.new(@task, @order_item).process
      else
        Rails.logger.info("Incoming task has no current relevant delegation")
      end
    end

    def process_error_tasks
      if @task.state == "running"
        Rails.logger.error("Incoming task #{@task.id} had an error while running: #{@task.context}")
      elsif @task.state == "completed"
        process_relevant_context
        Rails.logger.error("Incoming task #{@task.id} is completed but errored: #{@task.context}")
        @order_item.mark_failed
      end
    end

    def find_relevant_order_item
      @order_item = OrderItem.find_by!(:topology_task_ref => @task.id)
    end
  end
end
