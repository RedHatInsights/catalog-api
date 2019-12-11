module Catalog
  class CreateApprovalRequest
    attr_reader :order

    def initialize(task)
      @task = task
      @order = OrderItem.find_by!(:topology_task_ref => task.id).order
    end

    def process
      @order.order_items.each do |order_item|
        submit_approval_requests(order_item)
      end

      @order.update(:state => "Approval Pending", :order_request_sent_at => Time.now.utc)
      self
    rescue Catalog::ApprovalError => e
      Rails.logger.error("Error putting in approval Request for #{order.id}: #{e.message}")
      raise
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Error creating ApprovalRequest object for #{order.id}: #{e.message}")
      raise
    end

    private

    def submit_approval_requests(order_item)
      response = Approval::Service.call(ApprovalApiClient::RequestApi) do |api|
        api.create_request(Catalog::CreateRequestBodyFrom.new(@order, order_item, @task).process.result)
      end

      order_item.approval_requests.create!(
        :approval_request_ref => response.id,
        :state                => response.decision.to_sym
      )

      order_item.update_message("info", "Approval Request Submitted for ID: #{order_item.approval_requests.last.id}")
    end
  end
end
