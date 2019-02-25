module ServiceCatalog
  class TopologyError < StandardError; end
  class RBACError < StandardError; end
  class NotAuthorized < StandardError; end
end
