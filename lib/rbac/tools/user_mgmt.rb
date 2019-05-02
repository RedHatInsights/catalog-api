module RBAC
  module Tools
    class UserMgmt < Base
      def initialize(options)
        @options = options.dup
        @request = create_request(@options[:user_file])
        @users = @options[:users].split(',')
      end

      def process
        ManageIQ::API::Common::Request.with_request(@request) do
          get_group_uuid
          if @options[:mode] == "add"
            add_to_group
          elsif @options[:mode] == "remove"
            remove_from_group
          else
            puts "Invalid mode #{@options[:mode]}"
          end
        end
      end

      private

      def get_group_uuid
        match = RBAC::Service.call(RBACApiClient::GroupApi) do |api|
          RBAC::Service.paginate(api, :list_groups,  {}).detect do |grp|
            @options[:group].casecmp?(grp.name)
          end
        end
        raise "Group Name: #{@options[:group]} not found" unless match
        @group_uuid = match.uuid
      end

      def remove_from_group
        puts "Removing user #{@users} from group #{@options[:group]}"
        RBAC::Service.call(RBACApiClient::GroupApi) do |api|
          @users.each do |user|
            api.delete_principal_from_group(@group_uuid, user)
          end
        end
      end

      def add_to_group
        puts "Adding user #{@users} to group #{@options[:group]}"
        group_principal_in = RBACApiClient::GroupPrincipalIn.new
        group_principal_in.principals = @users.collect do |user|
          RBACApiClient::PrincipalIn.new.tap do |principal|
            principal.username = user
          end
        end
        RBAC::Service.call(RBACApiClient::GroupApi) do |api|
          api.add_principal_to_group(@group_uuid, group_principal_in)
        end
      end
    end
  end
end
