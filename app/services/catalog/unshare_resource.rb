module Catalog
  class UnshareResource
    require 'rbac-api-client'
    include Insights::API::Common::RBAC::Utilities

    def initialize(options)
      @group_uuids = SortedSet.new(options.fetch(:group_uuids, []))
      @permissions = options[:permissions]
      @object      = options[:object]
    end

    def process
      validate_groups
      AccessControlEntry.
        joins(:permissions).
        where(:group_uuid => @group_uuids,
              :aceable    => @object,
              :permissions => {:name => @permissions}).
        destroy_all
      self
    end
  end
end
