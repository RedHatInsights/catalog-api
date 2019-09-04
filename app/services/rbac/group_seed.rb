module RBAC
  class GroupSeed
    $seeded_tenants = {}

    def initialize(user)
      @user = user
    end

    def process
      self.tap do
        return unless @user.org_admin?
        return if $seeded_tenants[ActsAsTenant.current_tenant.external_tenant]

        RBAC::Seed.new(Rails.root.join('data', 'rbac_catalog_seed.yml')).process
        $seeded_tenants[ActsAsTenant.current_tenant.external_tenant] = true
      end
    end
  end
end
