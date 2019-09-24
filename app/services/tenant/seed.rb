module Tenant
  class Seed
    def initialize(tenant)
      @user = ManageIQ::API::Common::Request.current.user
      validate(tenant)
    end

    def self.validate
      account_number = ManageIQ::API::Common::Request.current.identity['identity']['account_number']
      raise Catalog::NotAuthorized if account_number != tenant.external_tenant
      raise Catalog::NotAuthorized if !@user.is_org_admin
      true
    end

    def process
      lookup_groups
      cache_tenant
      @seeded.data.present? ? nil : run_seeding
      self
    end

    private

    def run_seeding
      seeded = RBAC::Seed.new(Rails.root.join('data', 'rbac_catalog_seed.yml')).process
      RbacSeed.create!(:external_tenant => @user.tenant) if seeded
    end

    def cache_tenant
      RbacSeed.find_or_create_by(:external_tenant => @user.tenant) if @seeded.data.present?
    end

    def lookup_groups
      RBAC::Service.call(RBACApiClient::GroupApi) do |api_instance|
        @seeded = api_instance.list_groups
      end
    end
  end
end
