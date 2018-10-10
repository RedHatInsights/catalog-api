class ApplicationController < ActionController::API
  set_current_tenant_through_filter
  before_action :set_tenant_via_request_header

  def set_tenant_via_request_header
    identity = HeaderUtility.new(request.headers).decode('x-rh-auth-identity')['identity']
    current_tenant = Tenant.find_or_create_by(:ref_id => identity.fetch('org_id'))
    set_current_tenant(current_tenant)
  end
end
