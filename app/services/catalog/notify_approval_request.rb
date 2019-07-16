module Catalog
  class NotifyApprovalRequest
    EVENT_REQUEST_FINISHED = "request_finished".freeze

    attr_reader :notification_object

    def initialize(ref_id, payload)
      @notification_object = ApprovalRequest.find_by(:approval_request_ref => ref_id)
      @payload = payload
    end

    def process
      return self unless request_finished?

      @notification_object.update(:state => @payload["decision"], :reason => @payload["reason"])
      Catalog::ApprovalTransition.new(@notification_object.order_item.id).process

      self
    end

    private

    def request_finished?
      @payload["message"] == EVENT_REQUEST_FINISHED
    end
  end
end
