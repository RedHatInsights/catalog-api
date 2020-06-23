module Api
  module V1x0
    class TenantsController < ApplicationController
      include Mixins::IndexMixin

      def index
        collection(Tenant.scoped_tenants)
      end

      def show
        tenant = Tenant.scoped_tenants.find(params.require(:id))
        authorize(tenant)
        render :json => tenant
      end

      def seed
        tenant = Tenant.scoped_tenants.find(params.require(:tenant_id))
        authorize(tenant, :update?)
        seeded = Group::Seed.new(tenant).process
        json_response(nil, seeded.status)
      end
    end
  end
end
