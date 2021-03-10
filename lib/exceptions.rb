module Catalog
  class ApprovalError < StandardError; end
  class ConflictError < StandardError; end
  class InvalidParameter < StandardError; end
  class InvalidSurvey < StandardError; end
  class NotAuthorized < StandardError; end
  class OrderNotOrderable < StandardError; end
  class OrderUncancelable < StandardError; end
  class RBACError < StandardError; end
  class ServiceOfferingArchived < StandardError; end
  class SourcesError < StandardError; end
  class CatalogInventoryError < StandardError; end
end
