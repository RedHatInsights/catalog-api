module Catalog
  class Notify
    ACCEPTABLE_NOTIFICATION_CLASSES = %w[OrderItem ApprovalRequest]

    attr_reader :notification_object

    def initialize(klass, id, payload)
      raise Catalog::InvalidNotificationClass unless ACCEPTABLE_NOTIFICATION_CLASSES.include?(klass)

      @notification_object = klass.constantize.find(id)
      @payload = payload
    end

    def process
      @notification_object.update(:state, @payload[:decision])

      case @notification_object.class
      when OrderItem
        OrderStateTransition.new(@notification_object.order.id).process
      when ApprovalRequest
        ApprovalTransition.new(@notification_object.order_item.id).process
      end

      self
    end
  end
end
