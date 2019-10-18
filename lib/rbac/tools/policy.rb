module RBAC
  module Tools
    class Policy < Base
      private

      def list
        user_output
        ManageIQ::API::Common::RBAC::Service.call(RBACApiClient::PolicyApi) do |api|
          ManageIQ::API::Common::RBAC::Service.paginate(api, :list_policies, {}).each do |policy|
            list_output(policy)
          end
        end
      end

      def print_details(opts, object=nil)
        case opts
        when :user
          puts "Policies for tenant: #{@user['identity']['account_number']} org admin user: #{@user['identity']['user']['username']}"
          puts
        when :policy
          puts "\nPolicy Information"
          puts
          puts object.name
          puts object.description
          puts object.uuid
          puts "\n  Group Information"
          puts
          puts "  #{object.group.name}"
          puts "  #{object.group.uuid}"
          puts "\n    Role Information"
          puts
          object.roles.each do |role|
            puts "    #{role.name}"
            puts "    #{role.description}"
            puts "    #{role.uuid}"
          end
        end
      end
    end
  end
end
