module Catalog
  module RBAC
    class Access
      def initialize(user_context, record)
        @user_context = user_context
        @record = record
      end

      def update_access_check
        resource_check('update')
      end

      def read_access_check
        resource_check('read')
      end

      def create_access_check(klass)
        permission_check('create', klass)
      end

      def destroy_access_check
        resource_check('delete')
      end

      def resource_check(verb, id = @record.id, klass = @record.class)
        return true unless rbac_enabled?

        scopes = access_object.scopes(klass.table_name, verb)
        if scopes.include?("admin")
          true
        elsif scopes.include?("group")
          ids = access_id_list(verb, klass)
          klass.try(:supports_access_control?) ? ids.include?(id.to_s) : true
        elsif scopes.include?("user")
          @record.owner == @user_context.request.user.username
        else
          Rails.logger.error("Error in resource checking for verb: #{verb}, object id: #{id}, object class: #{@record.class}, class to check scopes against: #{klass}")
          Rails.logger.error("Scope does not include admin, group, or user. List of scopes: #{scopes}")
          false
        end
      end

      def admin_access_check(table_name, verb)
        return true unless rbac_enabled?

        access_object.admin_scope?(table_name, verb)
      end

      def permission_check(verb, klass = @record.class)
        rbac_enabled? ? access_object.accessible?(klass.table_name, verb) : true
      end

      def approval_workflow_check
        return true unless rbac_enabled?

        read_scopes = access_object.scopes("workflows", "read")
        link_scopes = access_object.scopes("workflows", "link")
        unlink_scopes = access_object.scopes("workflows", "unlink")

        [read_scopes, link_scopes, unlink_scopes].all? do |scope|
          scope.include?("admin")
        end
      end

      private

      def rbac_enabled?
        @user_context.rbac_enabled?
      end

      def access_id_list(verb, klass)
        Catalog::RBAC::AccessControlEntries.new(@user_context.group_uuids).ace_ids(verb, klass)
      end

      def access_object
        @user_context.access
      end
    end
  end
end
