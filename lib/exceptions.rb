module Catalog
  class TopologyError < StandardError; end
  class RBACError < StandardError; end
  class NoTenantError < StandardError; end
  class ApprovalError < StandardError; end
end
