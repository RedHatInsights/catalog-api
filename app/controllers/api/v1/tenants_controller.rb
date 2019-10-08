module Api
  module V1
    class TenantsController < ApplicationController
      def index
        render :json => Tenant.all
      end

      def show
        render :json => Tenant.find(params.require(:id))
      end

      def seed
        seeded = Group::Seed.new(Tenant.find(params.require(:tenant_id))).process
        json_response(nil, seeded.status)
      rescue Catalog::NotAuthorized => e
        json_response({:errors => e.message }, :forbidden)
      end
    end
  end
end
