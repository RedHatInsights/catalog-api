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
        if scopes.include?("admin")
          return true
        elsif scopes.include?("group")
          ids = access_id_list(verb, klass)
          return false if klass.try(:supports_access_control?) && ids.exclude?(id.to_s)
        #TODO: scopes.include?("user")
        # We currently care about the "user" scope in index mixin by doing .by_owner,
        # what is the equivalent here?
        else
          return false
        end

        true
      end

      def permission_check(verb, klass = @record.class)
        return true unless rbac_enabled?

        return false unless access_object.accessible?(klass.table_name, verb)

        true
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
