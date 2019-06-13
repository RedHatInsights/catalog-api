module Catalog
  class Notify
    attr_reader :notification_object

    def initialize(notification_object)
      @notification_object = notification_object
    end

    def process
      # WIP - Originally I figured we would just use the notification
      # object and call .notify on it which could then delegate
      # to the OrderStateTransition and ApprovalTransition services,
      # but then there's really no use for this service since the
      # internal API could just call that.
      #
      # But likewise, having a case statement to use the correct service
      # also seems silly.
      #
      # So it boils down to if we care about only calling a service
      # in the controllers or if we're ok with a model doing stuff
      # that a service can do.

      # Option 1 - kinda ugly, kinda odd, but keeps the knowledge and
      # logic contained in this service.
      #
      # case @notification_object.class
      # when OrderItem
      #   OrderStateTransition.new(@notification_object.order.id).process
      # when ApprovalRequest
      #   ApprovalTransition.new(@notification_object.order_item.id).process
      # end

      # Option 2 - much cleaner, but then the model is calling the service
      # which seems odd too.
      #
      # @notification_object.notify
    end
  end
end
