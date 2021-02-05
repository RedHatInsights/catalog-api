module Catalog
  class UpdateOrderItem
    CRHC_PREFIX = 'expose_to_cloud_redhat_com_'.freeze

    def initialize(task, order_item = nil)
      @task       = task
      order_item ||= OrderItem.find_by!(:topology_task_ref => @task.id)
      @order_item = order_item
    end

    def process
      mark_item_based_on_status
    end

    private

    def mark_item_based_on_status
      case @task.status
      when "ok"
        case @task.state
        when "completed"
          @order_item.mark_completed("Order Item Completed", :service_instance_ref => service_instance_id, :artifacts => artifacts)
        when "running"
          @order_item.update_message("info", "Order Item Is Running")
          @order_item.update!(:external_url => @task.output[:url])
        end
      when "error"
        @order_item.mark_failed("Order Item Failed", :service_instance_ref => service_instance_id)
      end
    end

    def service_instance_id
      @service_instance_id ||= @task.output[:id] || @order_item.service_instance_ref.to_s
    end

    def artifacts
      Hash(@task.output[:artifacts]).each_with_object({}) do |(key, val), facts|
        facts[key.delete_prefix(CRHC_PREFIX)] = val if key.start_with?(CRHC_PREFIX)
      end
    end
  end
end
