module Catalog
  class TopologyError < StandardError; end
  class RBACError < StandardError; end
  class ApprovalError < StandardError; end
  class NotAuthorized < StandardError; end
  class InvalidNotificationClass < StandardError; end
  class InvalidParameter < StandardError; end
  class OrderUncancelable < StandardError; end
end
