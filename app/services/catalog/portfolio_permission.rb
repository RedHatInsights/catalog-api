module Catalog
  class PortfolioPermission
    VALID_RESOURCE_VERBS = %w[read write order].freeze

    def self.verify_permissions(values)
      values.each do |perm|
        perm_list = perm.split(':')
        raise Catalog::InvalidParameter, "Permission should be : delimited and contain app_name:resource:verb, where verb has to be one of #{VALID_RESOURCE_VERBS}" unless perm_list.length == 3
        raise Catalog::InvalidParameter, "Permission app_name should be catalog" unless perm_list.first == 'catalog'
        raise Catalog::InvalidParameter, "Only portfolio objects can be shared" unless perm_list[1] == 'portfolios'
        raise Catalog::InvalidParameter, "Verbs should be one of #{VALID_RESOURCE_VERBS}" unless VALID_RESOURCE_VERBS.include?(perm_list[2])
      end
    end
  end
end
