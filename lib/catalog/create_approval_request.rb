module Catalog
  class CreateApprovalRequest
    attr_reader :order

    def initialize(task, order_item = nil)
      @task = task
      order_item ||= OrderItem.find_by!(:topology_task_ref => task.id)
      @order = order_item.order
    end

    def process
      # Possibly in the future we may want to create approval requests for
      # a before or after order item, but currently it is only for the
      # applicable product.
      @order.order_items.where(:process_scope => 'applicable').each do |order_item|
        submit_approval_requests(order_item)
      end

      @order.update(:state => "Approval Pending", :order_request_sent_at => Time.now.utc)
      self
    rescue ::Catalog::ApprovalError => e
      @order.order_items.first.mark_failed("Error while creating approval request")
      Rails.logger.error("Error putting in approval Request for #{order.id}: #{e.message}")
      raise
    end

    private

    def submit_approval_requests(order_item)
      response = Approval::Service.call(ApprovalApiClient::RequestApi) do |api|
        api.create_request(Catalog::CreateRequestBodyFrom.new(@order, order_item, @task).process.result)
      end

      order_item.approval_requests.create!(
        :approval_request_ref => response.id,
        :state                => response.decision.to_sym,
        :tenant_id            => order_item.tenant_id
      )

      Rails.logger.info("Approval Requests Submitted for Order #{@order.id}")
    end
  end
end
