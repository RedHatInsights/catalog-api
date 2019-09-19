module Api
  module V1x0
    class RbacController < ApplicationController
      before_action :get_current_user

      def seed
        if RBAC::GroupSeed.new(@current_user).process.nil?
          json_response({:message => "Tenant #{@current_user.tenant} already seeded" })
        else
          render :json => group_seed, :status => :ok
        end
      end

      def seeded?
        render :json => RbacSeed.seeded(@current_user).present?
      end

      private

      def get_current_user
        @current_user = ManageIQ::API::Common::Request.current.user
      end
    end
  end
end
