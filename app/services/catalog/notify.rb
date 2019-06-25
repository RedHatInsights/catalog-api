module Catalog
  class Notify
    ACCEPTABLE_NOTIFICATION_CLASSES = %w[OrderItem ApprovalRequest].freeze
    EVENT_REQUEST_FINISHED = "request_finished".freeze

    attr_reader :notification_object

    def initialize(klass, id, payload)
      raise Catalog::InvalidNotificationClass unless ACCEPTABLE_NOTIFICATION_CLASSES.include?(klass.camelcase)

      @notification_object = klass.camelcase.constantize.find(id)
      @payload = payload
    end

    def process
      return self unless request_finished?

      @notification_object.update(:state => @payload["decision"])

      case @notification_object
      when OrderItem
        Catalog::OrderStateTransition.new(@notification_object.order.id).process
      when ApprovalRequest
        @notification_object.update(:reason => @payload["reason"])
        Catalog::ApprovalTransition.new(@notification_object.order_item.id).process
      end

      self
    end

    private

    def request_finished?
      @payload["message"] == EVENT_REQUEST_FINISHED
    end
  end
end
