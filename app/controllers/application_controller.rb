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

  around_action :with_current_request

  private

  # This would get moved into the Insights Common optional_auth paths.
  CATALOG_OPTIONAL_AUTH_PATHS = [
    %r{\A/health\z},
  ].freeze

  def with_current_request
    Insights::API::Common::Request.with_request(request) do |current|
      # TODO: move catalog_required_auth? paths to common gem once they are decided.
      if current.required_auth? && catalog_required_auth?(URI.parse(current.original_url).path)
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

  # moved to insights common optional auth paths.
  def catalog_required_auth?(uri_path)
    CATALOG_OPTIONAL_AUTH_PATHS.none? do |optional_auth_path_regex|
      optional_auth_path_regex.match(uri_path)
    end
  end
end
