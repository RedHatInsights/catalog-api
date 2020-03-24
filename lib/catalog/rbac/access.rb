module Catalog
  module RBAC
    class Access
      def initialize(user, record)
        @user = user
        @record = record
      end

      def update_access_check
        resource_check('update')
      end

      def read_access_check
        resource_check('read')
      end

      def create_access_check
        permission_check('create')
      end

      def destroy_access_check
        resource_check('delete')
      end

      def admin_check
        return true unless rbac_enabled?

        catalog_admin?
      end

      def resource_check(verb, id = @record.id, klass = @record.class)
        return true unless rbac_enabled?
        return true if catalog_admin?

        return false unless access_object.accessible?(@record.class.table_name, verb)
        ids = access_id_list(verb, klass)
        return false if klass.try(:supports_access_control?) && ids.exclude?(id.to_s)

        true
      end

      def permission_check(verb, klass = @record.class)
        return true unless rbac_enabled?

        return false unless access_object.accessible?(klass.table_name, verb)

        true
      end

      private

      def rbac_enabled?
        Insights::API::Common::RBAC::Access.enabled?
      end

      def catalog_admin?
        Catalog::RBAC::Role.catalog_administrator?
      end

      def access_id_list(verb, klass)
        Catalog::RBAC::AccessControlEntries.new.ace_ids(verb, klass)
      end

      def access_object
        @access_object ||= Insights::API::Common::RBAC::Access.new.process
      end
    end
  end
end
