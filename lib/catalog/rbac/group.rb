module Catalog
  module RBAC
    class Group
      include Insights::API::Common::RBAC::Utilities

      def initialize(group_uuids)
        @group_uuids = group_uuids
      end

      def check
        return unless rbac_enabled?

        validate_groups
      end

      private

      def rbac_enabled?
        Insights::API::Common::RBAC::Access.enabled?
      end
    end
  end
end
