module Catalog
  class CreateApprovalRequest
    attr_reader :order

    def initialize(id)
      @order = Order.find_by!(:id => id)
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
        api.create_request(request_body_from(order_item))
      end
      order_item.approval_requests << create_approval_request(response, order_item)

      order_item.update_message("info", "Approval Request Submitted for ID: #{order_item.approval_requests.last.id}")
    end

    def request_body_from(order_item)
      svc_params_sanitized = Catalog::OrderItemSanitizedParameters.new(:order_item_id => order_item.id).process
      local_tag_resources = Catalog::CollectLocalTagResources.new(:order_id => @order.id).process.tag_resources

      ApprovalApiClient::RequestIn.new.tap do |request|
        request.name      = order_item.portfolio_item.name
        request.content   = {
          :product   => order_item.portfolio_item.name,
          :portfolio => order_item.portfolio_item.portfolio.name,
          :order_id  => order_item.order_id.to_s,
          :params    => svc_params_sanitized
        }
        request.tag_resources = local_tag_resources
      end
    end

    def create_approval_request(req, order_item)
      ApprovalRequest.create!(
        :workflow_ref         => req.workflow_id,
        :approval_request_ref => req.id,
        :state                => req.decision.to_sym,
        :order_item           => order_item
      )
    end
  end
end
