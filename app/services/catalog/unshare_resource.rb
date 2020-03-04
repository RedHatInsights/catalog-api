module Catalog
  class UnshareResource
    def initialize(options)
      @group_uuids = SortedSet.new(options.fetch(:group_uuids, []))
      @permissions = options[:permissions]
      @object      = options[:object]
    end

    def process
      Insights::API::Common::RBAC::ValidateGroups.new(@group_uuids).process

      AccessControlEntry
        .joins(:permissions)
        .where(:group_uuid  => @group_uuids,
               :aceable     => @object,
               :permissions => {:name => @permissions})
        .destroy_all
      self
    end
  end
end
