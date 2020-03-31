module Catalog
  class ShareInfo
    require 'rbac-api-client'
    attr_reader :result
    MAX_GROUPS_LIMIT = 500

    def initialize(options)
      @object = options[:object]
    end

    def process
      group_permissions = {}
      uuids = @object.access_control_entries.collect do |ace|
        group_permissions[ace.group_uuid] = ace.permissions.map(&:name)
        ace.group_uuid
      end

      group_names = fetch_group_names(uuids.uniq)
      @result = group_permissions.each_with_object([]) do |(uuid, permissions), memo|
        if group_names.key?(uuid)
          memo << { :group_name => group_names[uuid], :group_uuid => uuid, :permissions => permissions }
        else
          Rails.logger.warn("Skipping group UUID: #{uuid} since its missing from RBAC service")
        end
      end
      self
    end

    private

    def fetch_group_names(uuids)
      opts = {:limit => MAX_GROUPS_LIMIT, :uuid => uuids}
      Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
        Insights::API::Common::RBAC::Service.paginate(api, :list_groups, opts).each_with_object({}) do |group, memo|
          memo[group.uuid] = group.name
        end
      end
    end
  end
end
