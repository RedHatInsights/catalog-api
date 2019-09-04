class ApplicationController < ActionController::API
  include Response
  include Api::V1x0::Mixins::RBACMixin

  around_action :with_current_request

  private

  def with_current_request
    ManageIQ::API::Common::Request.with_request(request) do |current|
      if current.required_auth?
        raise ManageIQ::API::Common::EntitlementError, "User not Entitled" unless check_entitled(current.entitlement)

        ActsAsTenant.with_tenant(current_tenant(current.user)) do
          validate_rbac_groups(current.user)
          yield
        end
      else
        ActsAsTenant.without_tenant { yield }
      end
    end
  rescue ManageIQ::API::Common::EntitlementError => e
    json_response({:errors => e.message}, :forbidden)
  rescue ManageIQ::API::Common::IdentityError => e
    json_response({:errors => e.message}, :unauthorized)
  end

  def current_tenant(current_user)
    Tenant.find_or_create_by(:external_tenant => current_user.tenant)
  end

  def check_entitled(entitlement)
    required_entitlements = %i[hybrid_cloud?]

    required_entitlements.map { |e| entitlement.send(e) }.all?
  end

  def validate_rbac_groups(user)
    Thread.new do
      return unless user.org_admin?
      RBAC::GroupSeed.new(user).process
    end
  end
end
