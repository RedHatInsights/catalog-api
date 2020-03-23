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

        return false unless @catalog_access.accessible?(@record.class.table_name, verb, ENV['APP_NAME'])
        return true if @catalog_access.admin_scope?(@record.class.table_name, verb, ENV['APP_NAME'])

        ids = access_id_list(verb, klass)
        return false if klass.try(:supports_access_control?) && ids.exclude?(id.to_s)

        true
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

      def access_object(table_name, verb)
        Insights::API::Common::RBAC::Access.new(table_name, verb).process
      end
    end
  end
end
