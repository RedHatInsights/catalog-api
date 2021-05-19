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
    end
  end
end
