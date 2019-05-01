module RBAC
  module Tools
    class Group
      def initialize(options)
        @options = options.dup
        @debug = options[:debug]
        @request = create_request(@options[:user_file])
      end

      def process
        ManageIQ::API::Common::Request.with_request(@request) do
          list_groups
        end
      end

      private

      def list_groups
        @debug ? (puts @user) : print_details(:user)
        RBAC::Service.call(RBACApiClient::GroupApi) do |api|
          RBAC::Service.paginate(api, :list_groups,  {}).each do |group|
            @debug ? (puts group) : print_details(:group, group)
          end
        end
      end

      def print_details(opts, object=nil)
        case opts
        when :user
          puts "Policies for tenant: #{@user['identity']['account_number']} org admin user: #{@user['identity']['user']['username']}"
          puts
        when :group
          puts "\nGroup Name: #{object.name}"
          puts "Description: #{object.description}"
          puts "UUID: #{object.uuid}"
        end
      end

      def create_request(user_file)
        raise "File #{user_file} not found" unless File.exist?(user_file)
        @user = YAML.load_file(user_file)
        {:headers => {'x-rh-identity' => Base64.strict_encode64(@user.to_json)}, :original_url => '/'}
      end
    end
  end
end
