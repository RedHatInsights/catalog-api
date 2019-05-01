module RBAC
  module Tools
    class Role
      def initialize(options)
        @options = options.dup
        @request = create_request(@options[:user_file])
      end

      def process
        ManageIQ::API::Common::Request.with_request(@request) do
          list_roles
        end
      end

      private

      def list_roles
        RBAC::Service.call(RBACApiClient::RoleApi) do |api|
          RBAC::Service.paginate(api, :list_roles,  {}).each do |role|
            puts role
          end
        end
      end

      def create_request(user_file)
        raise "File #{user_file} not found" unless File.exist?(user_file)
        user = YAML.load_file(user_file)
        {:headers => {'x-rh-identity' => Base64.strict_encode64(user.to_json)}, :original_url => '/'}
      end
    end
  end
end
