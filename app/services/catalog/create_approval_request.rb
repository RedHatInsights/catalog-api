module Catalog
  class CreateApprovalRequest
    attr_reader :order

    def initialize(topic)
      # @order = Order.find_by!(:id => id)
      # @applied_inventories = applied_inventories
      # @message = topic.message
      @payload = topic.payload
      @order = OrderItem.find_by!(:topology_task_ref => @payload["task_id"]).order
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
    end

    private

    def submit_approval_requests(order_item)
      response = Approval::Service.call(ApprovalApiClient::RequestApi) do |api|
        api.create_request(Catalog::CreateRequestBodyFrom.new(@order, order_item).process.result)
      end
      order_item.approval_requests << create_approval_request(response, order_item)

      order_item.update_message("info", "Approval Request Submitted for ID: #{order_item.approval_requests.last.id}")
    end

    def create_approval_request(req, order_item)
      ApprovalRequest.create!(
        :approval_request_ref => req.id,
        :state                => req.decision.to_sym,
        :order_item           => order_item
      )
    end
  end
end
