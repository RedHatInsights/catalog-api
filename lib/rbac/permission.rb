module RBAC
  class Permission
    VALID_RESOURCE_VERBS = %w(read write order).freeze

    def self.verify_permissions(value)
      raise Catalog::InvalidParameter.new('Permission should be an array') unless value.kind_of?(Array)
      value.each do |perm|
        perm_list = perm.split(':')
        raise Catalog::InvalidParameter.new("Permission should be : delimited and contain app_name:resource:verb, where verb has to be one of #{VALID_RESOURCE_VERBS}") unless perm_list.length == 3
        raise Catalog::InvalidParameter.new("Permission app_name should be catalog") unless perm_list.first == 'catalog'
        raise Catalog::InvalidParameter.new("Only portfolio objects can be shared") unless perm_list[1] == 'portfolios'
        raise Catalog::InvalidParameter.new("Verbs should be one of #{VALID_RESOURCE_VERBS}") unless VALID_RESOURCE_VERBS.include?(perm_list[2])
      end
    end
  end
end
