module Catalog
  class TopologyError < StandardError; end
  class RBACError < StandardError; end
  class ApprovalError < StandardError; end
  class NotAuthorized < StandardError; end
  class InvalidParameter < StandardError; end
  class OrderUncancelable < StandardError; end
  class SourcesError < StandardError; end
  class InvalidSurvey < StandardError; end
  class ConflictError < StandardError; end
end
