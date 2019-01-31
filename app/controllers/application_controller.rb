class ApplicationController < ActionController::API

  private
  set_current_tenant_through_filter
  before_action :set_the_current_tenant

  def set_the_current_tenant
    return unless ENV["ENFORCE_TENANCY"]

    tenant = Tenant.find_by(:external_tenant => user_identity)
    if tenant
      set_current_tenant(tenant)
    else
      render :json => { :errors => "Unauthorized" }, :status => :unauthorized
    end
  end

  def user_account_number
    Base64.decode64(request.headers.fetch_path("x-rh-identity", "identity", "account_number"))
  end

  def user_identity
    # x-rh-identity = {
    #     "identity" => {
    #         "account_number" => 123456,
    #         "type" => "String"
    #     },
    #     "user" => {},
    #     "system" => {},
    #     "internal" => {},
    # }
    ident_key = "x-rh-identity"
    ManageIQ::API::Common::Headers.current = request.headers
    return unless ManageIQ::API::Common::Headers.current.key?(ident_key)

    ident = JSON.parse(Base64.decode64(request.headers[ident_key]))
    ident.fetch_path("identity", "account_number")
  end
end
