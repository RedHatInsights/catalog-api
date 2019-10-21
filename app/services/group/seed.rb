module Group
  class Seed
    attr_reader :status

    def initialize(tenant)
      @user = ManageIQ::API::Common::Request.current.user
      validate(tenant)
    end

    def validate(tenant)
      account_number = ManageIQ::API::Common::Request.current.identity['identity']['account_number']
      raise Catalog::NotAuthorized if account_number != tenant.external_tenant
      raise Catalog::NotAuthorized unless @user.org_admin?

      true
    end

    def tenant
      @user.tenant
    end

    def code(status)
      @status = status
    end

    def process
      lookup_groups
      mark_as_seeded
      @seeded.data.present? ? code(204) : run_seeding
      self
    end

    private

    def run_seeding
      seeded = ManageIQ::API::Common::RBAC::Seed.new(Rails.root.join('data', 'rbac_catalog_seed.yml')).process
      if seeded
        RbacSeed.create!(:external_tenant => @user.tenant)
        code(200)
      end
    end

    def mark_as_seeded
      RbacSeed.find_or_create_by(:external_tenant => @user.tenant) if @seeded.data.present?
    end

    def lookup_groups
      ManageIQ::API::Common::RBAC::Service.call(RBACApiClient::GroupApi) do |api_instance|
        @seeded = api_instance.list_groups
      end
    end
  end
end
