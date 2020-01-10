module Catalog
  class DetermineTaskRelevancy
    def initialize(topic)
      @topic = topic
    end

    def process
      Insights::API::Common::Request.with_request(order_item_context) do
        @task = TopologicalInventoryApiClient::Task.new(
          :id      => @topic.payload["task_id"],
          :state   => @topic.payload["state"],
          :status  => @topic.payload["status"],
          :context => @topic.payload["context"].try(&:with_indifferent_access)
        )

        @task.state == "completed" ? delegate_task : add_task_update_message
      end

      self
    rescue StandardError => exception
      add_update_message(:error) unless @task.nil?
      Rails.logger.error(exception.inspect)
    end

    private

    def delegate_task
      if @task.context.has_key_path?(:service_instance, :id)
        Catalog::UpdateOrderItem.new(@topic, @task).process
      elsif @task.context.has_key_path?(:applied_inventories)
        Rails.logger.info("Creating approval request for task")
        Catalog::CreateApprovalRequest.new(@task).process
      else
        add_task_update_message
      end
    end

    def order_item
      @order_item ||= OrderItem.find_by!(:topology_task_ref => @topic.payload["task_id"])
    end

    def order_item_context
      order_item.context.transform_keys(&:to_sym)
    end

    def add_task_update_message
      @task.status == "error" ? add_update_message(:error) : add_update_message(:info)
    end

    def add_update_message(state)
      message = "Task update. State: #{@task.state}. Status: #{@task.status}. Context: #{@task.context}"
      order_item.update_message(state, message)
      Rails.logger.send(state, message)
    end
  end
end
