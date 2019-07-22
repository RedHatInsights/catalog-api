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

      @order.update(:state => "Approval Pending", :ordered_at => Time.now.utc)
      self
    rescue Catalog::ApprovalError => e
      Rails.logger.error("Error putting in approval Request for #{order.id}: #{e.message}")
      raise
    end

    private

    def submit_approval_requests(order_item)
      workflows(order_item.portfolio_item).each do |workflow|
        response = Approval::Service.call(ApprovalApiClient::RequestApi) { |api| api.create_request(workflow, request_body_from(order_item)) }
        order_item.approval_requests << create_approval_request(response)

        order_item.update_message("info", "Approval Request Submitted for workflow #{workflow}, ID: #{order_item.approval_requests.last.id}")
      end
    end

    def request_body_from(order_item)
      svc_params_sanitized = Catalog::OrderItemSanitizedParameters.new(:order_item_id => order_item.id).process

      ApprovalApiClient::RequestIn.new.tap do |request|
        request.name      = order_item.portfolio_item.name
        request.content   = {
          :product   => order_item.portfolio_item.name,
          :portfolio => order_item.portfolio_item.portfolio.name,
          :order_id  => order_item.order_id.to_s,
          :params    => svc_params_sanitized
        }
      end
    end

    def workflows(portfolio_item)
      portfolio_item.resolved_workflow_refs
    end

    def create_approval_request(req)
      ApprovalRequest.new.tap do |approval|
        approval.workflow_ref         = req.workflow_id
        approval.approval_request_ref = req.id
        approval.state                = req.decision.to_sym
        approval.save!
      end
    end
  end
end
