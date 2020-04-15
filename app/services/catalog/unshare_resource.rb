module Catalog
  class UnshareResource
    def initialize(options)
      @group_uuids = SortedSet.new(options.fetch(:group_uuids, []))
      @permissions = options[:permissions]
      @object      = options[:object]
    end

    def process
      Insights::API::Common::RBAC::ValidateGroups.new(@group_uuids).process

      permission_ids = Permission.where(:name => @permissions).pluck(:id)
      access_control_entry_id = AccessControlEntry.where(:group_uuid => @group_uuids, :aceable => @object).first.id

      AccessControlPermission
        .where(:permission_id => permission_ids, :access_control_entry_id => access_control_entry_id)
        .destroy_all

      self
    end
  end
end
