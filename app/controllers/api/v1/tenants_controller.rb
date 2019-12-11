module Api
  module V1
    class TenantsController < ApplicationController
      include Api::V1::Mixins::IndexMixin

      def index
        collection(Tenant.scoped_tenants)
      end

      def show
        render :json => Tenant.scoped_tenants.find(params.require(:id))
      end

      def seed
        seeded = Group::Seed.new(Tenant.scoped_tenants.find(params.require(:tenant_id))).process
        json_response(nil, seeded.status)
      end
    end
  end
end
