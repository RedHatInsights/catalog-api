class ApplicationController < ActionController::API
  include Response
  include Api::V1::Mixins::RBACMixin
  include ManageIQ::API::Common::ApplicationControllerMixins::ApiDoc
  include ManageIQ::API::Common::ApplicationControllerMixins::Common
  include ManageIQ::API::Common::ApplicationControllerMixins::ExceptionHandling
  include ManageIQ::API::Common::ApplicationControllerMixins::RequestBodyValidation
  include ManageIQ::API::Common::ApplicationControllerMixins::RequestPath
  include ManageIQ::API::Common::ApplicationControllerMixins::Parameters

  around_action :with_current_request

  private

  def with_current_request
    ManageIQ::API::Common::Request.with_request(request) do |current|
      if current.required_auth?
        raise ManageIQ::API::Common::EntitlementError, "User not Entitled" unless check_entitled(current.entitlement)

        ActsAsTenant.with_tenant(current_tenant(current.user)) { yield }
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
    required_entitlements = %i[ansible?]

    required_entitlements.map { |e| entitlement.send(e) }.all?
  end
end
