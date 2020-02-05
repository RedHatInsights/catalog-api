module Catalog
  module RBAC
    class AccessControlEntries
      def initialize
        @my_group_uuids = Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
          Insights::API::Common::RBAC::Service.paginate(api, :list_groups, :scope => 'principal').collect(&:uuid)
        end
      end

      def ace_ids(permission, klass)
        AccessControlEntry.joins(:permissions).where(
          :permissions            => {
            :name => permission
          },
          :access_control_entries => {
            :group_uuid   => @my_group_uuids,
            :aceable_type => klass.to_s
          }
        ).collect { |ace| ace.aceable_id.to_s }
      end
    end
  end
end
