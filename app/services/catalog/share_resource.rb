module Catalog
  class ShareResource
    def initialize(options)
      @group_uuids = SortedSet.new(options.fetch(:group_uuids, []))
      @permissions = options[:permissions]
      @object      = options[:object]
    end

    def process
      Insights::API::Common::RBAC::ValidateGroups.new(@group_uuids).process

      @group_uuids.each do |group_uuid|
        ace = AccessControlEntry.find_or_create_by(:group_uuid => group_uuid,
                                                   :aceable    => @object)
        ace.add_new_permissions(@permissions)
      end

      @object&.update_statistics

      self
    end
  end
end
