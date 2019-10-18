module RBAC
  module Tools
    class Role < Base
      private

      def list
        user_output
        ManageIQ::API::Common::RBAC::Service.call(RBACApiClient::RoleApi) do |api|
          ManageIQ::API::Common::RBAC::Service.paginate(api, :list_roles, {}).each do |role|
            list_output(role)
          end
        end
      end

      def print_details(opts, object=nil)
        case opts
        when :user
          puts "Policies for tenant: #{@user['identity']['account_number']} org admin user: #{@user['identity']['user']['username']}"
          puts
        when :role
          puts "\nRole Name: #{object.name}"
          puts "Description: #{object.description}"
          puts "UUID: #{object.uuid}"
        end
      end
    end
  end
end
