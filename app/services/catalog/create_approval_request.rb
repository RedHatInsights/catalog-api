require 'approval_api_client'

module Catalog
  class CreateApprovalRequest
    attr_reader :order

    def initialize(id)
      @order = Order.find_by!(:id => id)
    end

    def process
      @order.order_items.each do |order_item|
        approvals = send_approval_requests(order_item)
        approvals.compact.each do |req|
          order_item.approval_requests << create_approval_request(req)
        end
      end

      @order.update(:status => "Ordered", :ordered_at => Time.now.utc)
      self
    rescue Catalog::AprovalError => e
      Rails.logger.error("Error putting in approval Request for #{order.id}: #{e.message}")
      raise
    end

    private

    def send_approval_requests(order_item)
      workflows(order_item.portfolio_item).map do |workflow|
        Approval.call do |api_instance|
          api_instance.create_request(workflow, request_body_from(order_item))
        end
      end
    end

    def request_body_from(order_item)
      o_params = ActionController::Parameters.new('order_item_id' => order_item.id)
      svc_params_sanitized = Catalog::OrderItemSanitizedParameters.new(o_params).process

      ApprovalApiClient::RequestIn.new.tap do |request|
        request.requester = ManageIQ::API::Common::Request.current.user.username
        request.name      = order_item.portfolio_item.name
        request.content   = {
          :product   => order_item.portfolio_item.name,
          :portfolio => order_item.portfolio_item.portfolio.name,
          :order_id  => order_item.order_id,
          :params    => svc_params_sanitized.to_json
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
        approval.status               = req.decision
        approval.save
      end
    end
  end
end
