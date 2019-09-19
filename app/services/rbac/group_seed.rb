module RBAC
  class GroupSeed
    def initialize(user)
      @user = user
    end

    def process
      raise Catalog::NotAuthorized unless @user.org_admin?
      get_groups
      cache_tenant
      self.tap do
        seeded = RBAC::Seed.new(Rails.root.join('data', 'rbac_catalog_seed.yml'), @user).process
        RbacSeed.create!(:external_tenant => @user.account_number) if seeded
      end
    end

    private

    def cache_tenant
      RbacSeed.find_or_create_by(:external_tenant => @user.tenant) if @seeded.data.present?
    end

    def get_groups
      RBAC::Service.call(RBACApiClient::GroupApi) do |api_instance|
        @seeded = api_instance.list_groups
      end
    end
  end
end
