module Api
  module V1x3
    class TenantsController < Api::V1x2::TenantsController
      include Mixins::IndexMixin
      DEFAULT_GROUP_DESC = "System created Catalog & Approval administrator".freeze
      DEFAULT_ROLES = ["Catalog Administrator", "Approval Administrator"].freeze
      DEFAULT_GROUP_NAME = "Default Catalog & Approval Administrator".freeze

      def seed
        tenant = Tenant.scoped_tenants.find(params.require(:tenant_id))
        account_number = Insights::API::Common::Request.current.identity['identity']['account_number']
        raise ::Catalog::NotAuthorized if account_number != tenant.external_tenant
        raise ::Catalog::NotAuthorized unless Insights::API::Common::Request.current.user.org_admin?

        username = Insights::API::Common::Request.current.user.username
        if RbacSeed.where(:external_tenant => tenant.external_tenant).any?
          head :no_content
        else
          Api::V1x3::Catalog::AddToGroup.new(DEFAULT_GROUP_NAME, DEFAULT_GROUP_DESC, DEFAULT_ROLES, username).process
          Api::V1x3::Catalog::SeedPortfolios.new.process
          RbacSeed.create(:external_tenant => tenant.external_tenant)
          head :created
        end
      end
    end
  end
end
