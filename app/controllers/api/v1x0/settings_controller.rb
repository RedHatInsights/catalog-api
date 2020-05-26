module Api
  module V1x0
    class SettingsController < ApplicationController
      skip_before_action :validate_primary_collection_id

      def index
        authorize(tenant, :show?)
        settings = Catalog::TenantSettings.new(tenant)
        render :json => settings.process.response
      end

      def show
        authorize(tenant)
        render :json => { params.require(:id) => setting(params.require(:id)) }
      end

      def create
        authorize(tenant)
        tenant.add_setting(params.require(:name), params.require(:value))
        render :json => { params[:name] => setting(params[:name]) }
      end

      def update
        authorize(tenant, :update?)
        tenant.update_setting(params.require(:id), params.require(:value))
        render :json => { params[:id] => setting(params[:id]) }
      end

      def destroy
        authorize(tenant, :update?)
        tenant.delete_setting(params.require(:id))
        head :no_content
      end

      private

      def setting(name)
        tenant.settings[name]
      end

      def tenant
        ActsAsTenant.current_tenant
      end
    end
  end
end
