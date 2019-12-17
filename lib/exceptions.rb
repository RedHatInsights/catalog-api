module Catalog
  class ApprovalError < StandardError; end
  class ConflictError < StandardError; end
  class InvalidParameter < StandardError; end
  class InvalidSurvey < StandardError; end
  class NotAuthorized < StandardError; end
  class OrderUncancelable < StandardError; end
  class RBACError < StandardError; end
  class SourcesError < StandardError; end
  class TopologyError < StandardError; end
end
