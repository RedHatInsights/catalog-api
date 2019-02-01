class ApplicationController < ActionController::API
  private

  set_current_tenant_through_filter
  before_action :set_the_current_tenant

  def set_the_current_tenant
    return unless ENV["ENFORCE_TENANCY"]

    account_number = identity_account_number
    tenant = Tenant.find_or_create_by(:external_tenant => account_number) if account_number.present?
    if tenant
      set_current_tenant(tenant)
    else
      render :json => { :errors => "Unauthorized" }, :status => :unauthorized
    end
  end

  def identity_account_number
    ident_key = "x-rh-identity"
    ManageIQ::API::Common::Headers.current = request.headers
    return unless ManageIQ::API::Common::Headers.current.key?(ident_key)

    ident = JSON.parse(Base64.decode64(request.headers[ident_key]))
    ident.fetch_path("identity", "account_number")
  end
end
