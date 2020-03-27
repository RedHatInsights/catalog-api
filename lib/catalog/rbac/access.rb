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

      def resource_check(verb, id = @record.id, klass = @record.class)
        return true unless rbac_enabled?

        scopes = access_object.scopes(@record.class.table_name, verb)
        check = if scopes.include?("admin")
          true
        elsif scopes.include?("group")
          ids = access_id_list(verb, klass)
          !(klass.try(:supports_access_control?) && ids.exclude?(id.to_s))
        elsif scopes.include?("user")
          @record.owner == @user.user.user.username
        else
          false
        end

        check
      end

      def permission_check(verb, klass = @record.class)
        rbac_enabled? ? access_object.accessible?(klass.table_name, verb) : true
      end

      private

      def rbac_enabled?
        @user.rbac_enabled?
      end

      def access_id_list(verb, klass)
        Catalog::RBAC::AccessControlEntries.new.ace_ids(verb, klass)
      end

      def access_object
        @user.catalog_access
      end
    end
  end
end
