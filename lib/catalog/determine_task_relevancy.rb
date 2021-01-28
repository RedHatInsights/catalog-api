module Catalog
  class DetermineTaskRelevancy
    def initialize(topic)
      @topic = topic
    end

    def process
      @task = CatalogInventoryApiClient::Task.new(
        :id     => @topic.payload["task_id"].to_s,
        :state  => @topic.payload["state"],
        :status => @topic.payload["status"],
        :output => @topic.payload["context"].try(&:with_indifferent_access)
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
      if @task.output&.has_key_path?(:service_instance)
        UpdateOrderItem.new(@task, @order_item).process
      elsif @task.output&.has_key_path?(:applied_inventories)
        tag_resources = Tags::CollectTagResources.new(@task, @order_item.order).process.tag_resources

        Rails.logger.info("Evaluating order processes for order item id #{@order_item.id}")
        EvaluateOrderProcess.new(@task, @order_item.order, tag_resources).process

        Rails.logger.info("Creating approval request for task id #{@task.id}")
        CreateApprovalRequest.new(@task, tag_resources, @order_item).process
      else
        Rails.logger.info("Incoming task has no current relevant delegation")
      end
    end

    def process_error_tasks
      @order_item.update_message("error", "Task update message received with payload: #{@task}")
      if @task.state == "running"
        Rails.logger.error("Incoming task #{@task.id} had an error while running: #{@task.output}")
      elsif @task.state == "completed"
        Rails.logger.error("Incoming task #{@task.id} is completed but errored: #{@task.output}")
        if @task.output&.has_key_path?(:service_instance)
          UpdateOrderItem.new(@task, @order_item).process
        else
          @order_item.mark_failed("Order Item Failed")
        end
      end
    end

    def find_relevant_order_item
      @order_item = OrderItem.find_by!(:topology_task_ref => @task.id)
    end
  end
end
