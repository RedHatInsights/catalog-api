module Catalog
  class NotifyApprovalRequest
    EVENT_REQUEST_FINISHED = "request_finished".freeze
    EVENT_REQUEST_CANCELED = "request_canceled".freeze
    COMPLETED_EVENTS = [EVENT_REQUEST_FINISHED, EVENT_REQUEST_CANCELED].freeze

    attr_reader :notification_object

    def initialize(ref_id, payload, message)
      @notification_object = ApprovalRequest.find_by(:approval_request_ref => ref_id)
      @payload = payload
      @message = message
    end

    def process
      return self unless request_complete?

      update_approval_request
      Catalog::ApprovalTransition.new(@notification_object.order_item.id).process

      self
    end

    private

    def request_complete?
      COMPLETED_EVENTS.include?(@message)
    end

    def update_approval_request
      case @message
      when EVENT_REQUEST_CANCELED
        state = "canceled"
      when EVENT_REQUEST_FINISHED
        state = @payload["decision"]
      end

      @notification_object.update(
        :state                => state,
        :reason               => @payload["reason"],
        :request_completed_at => Time.now.utc
      )
    end
  end
end
