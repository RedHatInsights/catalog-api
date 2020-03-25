module Catalog
  module RBAC
    class Access
      def initialize(user, record)
        @user = user
        @record = record
        @catalog_access = @user.catalog_access
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

      def resource_check(verb, id = @record.id, klass = @record.class)
        return true unless rbac_enabled?

        scopes = @catalog_access.scopes(@record.class.table_name, verb)
        if scopes.include?('admin')
          return true
        elsif scopes.include?('group')
          ids = access_id_list(verb, klass)
          return false if klass.try(:supports_access_control?) && ids.exclude?(id.to_s)
        else
          false
        end
      end

      def permission_check(verb, klass = @record.class)
        return true unless rbac_enabled?

        return false unless @catalog_access.accessible?(klass.table_name, verb)

        true
      end

      private

      def rbac_enabled?
        Insights::API::Common::RBAC::Access.enabled?
      end

      def access_id_list(verb, klass)
        Catalog::RBAC::AccessControlEntries.new.ace_ids(verb, klass)
      end
    end
  end
end
