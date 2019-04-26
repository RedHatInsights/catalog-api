class ApplicationController < ActionController::API
  include Response
  rescue_from Catalog::TopologyError, :with => :topology_service_error
  rescue_from Catalog::NotAuthorized, :with => :forbidden_error
  rescue_from ManageIQ::API::Common::IdentityError, :with => :unauthorized_error

  around_action :with_current_request

  private

  def with_current_request
    ManageIQ::API::Common::Request.with_request(request) do |current|
      begin
        ActsAsTenant.with_tenant(current_tenant(current.user)) { yield }
      rescue ManageIQ::API::Common::IdentityError
        json_response({ :message => 'Unauthorized' }, :unauthorized)
      end
    end
  end

  def current_tenant(current_user)
    Tenant.find_or_create_by(:external_tenant => current_user.tenant)
  end
end
