module Api
  module V1x1
    class TenantsController < ApplicationController
      skip_before_action :validate_request, :only => %i[seed]
      skip_before_action :validate_primary_collection_id, :only => %i[seed]
      include Api::V1::Mixins::IndexMixin

      def index
        collection(Tenant.scoped_tenants)
      end

      def show
        render :json => Tenant.scoped_tenants.find(params.require(:id))
      end

      def seed
        seeded = Group::V1x1Seed.new.process
        json_response(nil, seeded.status)
      end
    end
  end
end
