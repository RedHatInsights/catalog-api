module Api
  module V1x3
    module Catalog
      class AddToGroup
        attr_reader :result

        def initialize(group_name, group_description, role_names, user_name)
          @group_name = group_name
          @group_description = group_description
          @role_names  = role_names
          @user_name  = user_name
          @result = false
        end

        def process
          Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
            group_uuid = get_group_uuid(api)
            if group_uuid.nil?
              group_uuid = add_group(api)
            end
            add_roles_to_group(api, group_uuid)
            add_principal_to_group(api, group_uuid)
            @result = true
            self
          end
        end

        private

        def add_group(api)
          group = RBACApiClient::Group.new(name: @group_name, description: @group_description)
          result = api.create_group(group)
          result.uuid
        rescue RBACApiClient::ApiError => e
          Rails.logger.error("Exception when calling GroupApi->create_group: #{e.message}")
          raise "Error adding group #{@group_name}"
        end

        def add_roles_to_group(api, group_uuid)
          @role_names.each do |role_name|
            if !role_exists_in_group?(api, role_name, group_uuid)
              add_role_to_group(api, role_name, group_uuid)
            end
          end
        end

        def get_role_uuid(role_name)
          Insights::API::Common::RBAC::Service.call(RBACApiClient::RoleApi) do |api|
            opts = { name: role_name }
            result = api.list_roles(opts)
            result.meta.count == 1 ? result.data.first.uuid : nil
          end
        rescue RBACApiClient::ApiError => e
          Rails.logger.error("Exception when calling RoleApi->list_roles: #{e}")
          raise "Error getting role uuid for #{role_name}"
        end

        def get_group_uuid(api)
          opts = { name: @group_name }
          result = api.list_groups(opts)
          result.meta.count == 1 ? result.data.first.uuid : nil 
        rescue RBACApiClient::ApiError => e
          Rails.logger.error("Exception when calling GroupApi->list_groups: #{e}")
          raise "Error getting group uuid for #{@group_name}"
        end

        def role_exists_in_group?(api, role_name, group_uuid)
          opts = { role_name: role_name }
          result = api.list_roles_for_group(group_uuid, opts)
          return result.meta.count == 1
        rescue RBACApiClient::ApiError => e
          Rails.logger.error("Exception when calling GroupApi->list_roles_for_group: #{e}")
          raise "Error checking if role #{role_name} exists in group #{@group_name}"
        end

        def add_role_to_group(api, role_name, group_uuid)
          role_uuid = get_role_uuid(role_name)
          if role_uuid.nil?
            raise "Role #{role_name} does not exist"
          end
          group_role_in = RBACApiClient::GroupRoleIn.new 
          group_role_in.roles = [role_uuid]
          api.add_role_to_group(group_uuid, group_role_in)
        rescue RBACApiClient::ApiError => e
          Rails.logger.error("Exception when calling GroupApi->add_role_to_group: #{e}")
          raise "Error adding role #{role_name} to group #{@group_name}"
        end

        def add_principal_to_group(api, group_uuid)
          group_principal_in = RBACApiClient::GroupPrincipalIn.new
          principal = RBACApiClient::PrincipalIn.new(username: @user_name)
          group_principal_in.principals = [principal]
          api.add_principal_to_group(group_uuid, group_principal_in)
        rescue RBACApiClient::ApiError => e
          Rails.logger.error("Exception when calling GroupApi->add_principal_to_group: #{e}")
          raise "Error adding user #{@user_name} to group #{@group_name}"
        end
      end
    end
  end
end
