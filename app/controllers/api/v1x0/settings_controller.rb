module Api
  module V1x0
    class SettingsController < ApplicationController
      before_action :org_admin_check

      def index
        render :json => tenant.settings
      end

      def show
        render :json => { params.require(:id) => setting(params.require(:id)) }
      end

      def create
        tenant.add_setting(params.require(:name), params.require(:value))
        render :json => { params[:name] => setting(params[:name]) }
      end

      def update
        tenant.update_setting(params.require(:id), params.require(:value))
        render :json => { params[:id] => setting(params[:id]) }
      end

      def destroy
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
