class ApplicationController < ActionController::API
  include Response
  include Api::V1::Mixins::ACEMixin
  include Api::V1::Mixins::RBACMixin
  include Insights::API::Common::ApplicationControllerMixins::ApiDoc
  include Insights::API::Common::ApplicationControllerMixins::Common
  include Insights::API::Common::ApplicationControllerMixins::ExceptionHandling
  include Insights::API::Common::ApplicationControllerMixins::RequestBodyValidation
  include Insights::API::Common::ApplicationControllerMixins::RequestPath
  include Insights::API::Common::ApplicationControllerMixins::Parameters
  include Pundit

  around_action :with_current_request

  private

  def with_current_request
    Insights::API::Common::Request.with_request(request) do |current|
      if current.required_auth?
        raise Insights::API::Common::EntitlementError, "User not Entitled" unless check_entitled(current.entitlement)

        ActsAsTenant.with_tenant(current_tenant(current.user)) { yield }
      else
        ActsAsTenant.without_tenant { yield }
      end
    end
  rescue Insights::API::Common::EntitlementError => e
    json_response({:errors => e.message}, :forbidden)
  rescue Insights::API::Common::IdentityError => e
    json_response({:errors => e.message}, :unauthorized)
  end

  def current_tenant(current_user)
    Tenant.find_or_create_by(:external_tenant => current_user.tenant)
  end

  def check_entitled(entitlement)
    required_entitlements = %i[ansible?]

    required_entitlements.map { |e| entitlement.send(e) }.all?
  end

  def pundit_user
    Insights::API::Common::Request.current!
  end
end
