require 'rake'

namespace :portfolios do
  desc "Remove RBAC roles for discarded portfolios"
  task :remove_discarded_rbac => :environment do
    raise "Please provide a user yaml file" unless ENV['USER_FILE']

    request = create_request(ENV['USER_FILE'])
    ManageIQ::API::Common::Request.with_request(request) do |current|
      delete_roles(current.user)
    end
  end

  def create_request(user_file)
    raise "File #{user_file} not found" unless File.exist?(user_file)

    user = YAML.load_file(user_file)
    {:headers => {'x-rh-identity' => Base64.strict_encode64(user.to_json)}, :original_url => '/'}
  end

  def current_tenant(current_user)
    Tenant.find_by!(:external_tenant => current_user.tenant)
  end

  def delete_roles(current_user)
    roles = fetch_roles
    ActsAsTenant.with_tenant(current_tenant(current_user)) do
      Portfolio.with_discarded.discarded.each do |portfolio|
        role_name_prefix = "catalog-portfolios-#{portfolio.id}-"
        matching_roles = roles.select do |role|
          role.name.start_with?(role_name_prefix)
        end

        matching_roles.each do |role|
          puts "Deleting role #{role.name}"
          RBAC::Service.call(RBACApiClient::RoleApi) do |api|
            api.delete_role(role.uuid)
          end
        end
      end
    end
  end

  def fetch_roles
    opts = { :limit => 500, :name => "catalog-portfolios" }
    RBAC::Service.call(RBACApiClient::RoleApi) do |api|
      RBAC::Service.paginate(api, :list_roles, opts).to_a
    end
  end
end
