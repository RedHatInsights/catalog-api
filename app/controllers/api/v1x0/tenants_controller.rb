module Api
  module V1x0
    class TenantsController < ApplicationController

      def index
        render :json => Tenant.all
      end

      def show
        render :json => Tenant.find(params.require(:id))
      end

      def seed
        RBAC::TenantSeed.new(Tenant.find(params.permit(:id))).process
        json_response({:message => "Tenant #{params.permit(:external_tenant)} seeded" }, :created)
      rescue Catalog::NotAuthorized => e
        json_response({:errors => e.message }, :forbidden)
      end
    end
  end
end
