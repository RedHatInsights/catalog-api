module RBAC
  module Tools
    class Group
      def initialize(options)
        @options = options.dup
        @request = create_request(@options[:user_file])
        @users = @options[:users].split(',')
      end

      def process
        ManageIQ::API::Common::Request.with_request(@request) do
          list_groups
        end
      end

      private

      def list_groups
        RBAC::Service.paginate(api, :list_groups,  {}).each do |grp|
          puts grp
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
