class ApplicationController < ActionController::API
  include Response
  include Api::V1x0::Mixins::RBACMixin
  rescue_from Catalog::TopologyError, :with => :topology_service_error
  rescue_from Catalog::NotAuthorized, :with => :forbidden_error
  rescue_from ManageIQ::API::Common::IdentityError, :with => :unauthorized_error
  rescue_from ManageIQ::API::Common::EntitlementError, :with => :forbidden_error

  around_action :with_current_request

  private

  def with_current_request
    ManageIQ::API::Common::Request.with_request(request) do |current|
      raise ManageIQ::API::Common::EntitlementError, "User not Entitled" unless check_entitled(current.entitlement)

      ActsAsTenant.with_tenant(current_tenant(current.user)) { yield }
    end
  end

  def current_tenant(current_user)
    Tenant.find_or_create_by(:external_tenant => current_user.tenant)
  end

  def check_entitled(entitlement)
    required_entitlements = %i[hybrid_cloud?]

    required_entitlements.map { |e| entitlement.send(e) }.all?
  end
end
