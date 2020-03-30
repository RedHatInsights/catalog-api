module Api
  module V1x0
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
          delegate_task if %w(completed running).include?(@task.state)
          order_item.mark_failed if @task.status == "error"

          self
        rescue StandardError => exception
          Rails.logger.error(exception.inspect)
          raise
        end

        private

        def delegate_task
          if @task.context.has_key_path?(:service_instance)
            Catalog::UpdateOrderItem.new(@topic, @task).process
          elsif @task.context.has_key_path?(:applied_inventories)
            Rails.logger.info("Creating approval request for task")
            Catalog::CreateApprovalRequest.new(@task).process
          else
            Rails.logger.info("Incoming task has no current relevant delegation")
          end
        end
      end
    end
  end
end
