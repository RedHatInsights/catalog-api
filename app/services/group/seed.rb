module Group
  class Seed
    attr_reader :status
    CATALOG_ADMINISTRATOR_GROUP = "Catalog Administrators".freeze

    def initialize(tenant)
      @request = Insights::API::Common::Request.current
      validate(tenant)
    end

    def validate(tenant)
      account_number = Insights::API::Common::Request.current.identity['identity']['account_number']
      raise Catalog::NotAuthorized if account_number != tenant.external_tenant
      raise Catalog::NotAuthorized unless @request.user.org_admin?

      true
    end

    def external_tenant
      @request.tenant
    end

    def code(status)
      @status = status
    end

    def process
      lookup_groups
      mark_as_seeded

      if @seeded.data.present?
        code(204)
      else
        run_seeding
        add_user_to_catalog_admin_group
      end

      self
    end

    private

    def run_seeding
      seeded = Insights::API::Common::RBAC::Seed.new(Rails.root.join('data', 'rbac_catalog_seed.yml')).process
      if seeded
        RbacSeed.create!(:external_tenant => external_tenant)
        code(200)
      end
    end

    def mark_as_seeded
      RbacSeed.find_or_create_by(:external_tenant => external_tenant) if @seeded.data.present?
    end

    def add_user_to_catalog_admin_group
      group_principal_in = RBACApiClient::GroupPrincipalIn.new.tap do |group|
        group.principals = [RBACApiClient::PrincipalIn.new(:username => @request.user.username)]
      end

      Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
        api.add_principal_to_group(group_uuid(CATALOG_ADMINISTRATOR_GROUP), group_principal_in)
      end
    end

    def group_uuid(group)
      match = Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api|
        Insights::API::Common::RBAC::Service.paginate(api, :list_groups, :name => group).detect do |grp|
          group == grp.name
        end
      end
      raise "Group Name: #{group} not found" unless match

      match.uuid
    end

    def lookup_groups
      Insights::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api_instance|
        @seeded = api_instance.list_groups
      end
    end
  end
end
