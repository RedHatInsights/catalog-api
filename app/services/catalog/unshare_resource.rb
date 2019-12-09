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
      @group_uuids.each do |group_uuid|
        @permissions.each do |permission|
          AccessControlEntry.where(:group_uuid  => group_uuid,
                                   :permission  => permission,
                                   :aceable     => @object).destroy_all
        end
      end
      self
    end
  end
end
