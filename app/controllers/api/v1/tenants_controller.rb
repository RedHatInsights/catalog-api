module Api
  module V1
    class TenantsController < ApplicationController
      def index
        render :json => Tenant.scoped_tenants
      end

      def show
        render :json => Tenant.scoped_tenants.find(params.require(:id))
      end

      def seed
        seeded = Group::Seed.new(Tenant.scoped_tenants.find(params.require(:tenant_id))).process
        json_response(nil, seeded.status)
      rescue Catalog::NotAuthorized => e
        json_response({:errors => e.message }, :forbidden)
      end
    end
  end
end
