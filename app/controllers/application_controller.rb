class ApplicationController < ActionController::API
  rescue_from ServiceCatalog::TopologyError, :with => :topology_service_error
  private

  set_current_tenant_through_filter
  before_action :set_current_headers
  before_action :set_the_current_tenant
  after_action :remove_current_headers_and_tenant

  def set_current_headers
    ManageIQ::API::Common::Request.current = request
  end

  def remove_current_headers_and_tenant
    ManageIQ::API::Common::Request.current = nil
    ActsAsTenant.current_tenant = nil
  end

  def set_the_current_tenant
    return unless Tenant.tenancy_enabled?
    begin
      account_number = ManageIQ::API::Common::Request.current.user.tenant rescue nil
    rescue ManageIQ::API::Common::HeaderIdentityError
      account_number = nil
    end
    tenant = Tenant.find_or_create_by(:external_tenant => account_number) if account_number.present?
    if tenant
      set_current_tenant(tenant)
    else
      render :json => { :errors => "Unauthorized" }, :status => :unauthorized
    end
  end

  def topology_service_error(err)
    render :json => {:message => err.message}, :status => :internal_server_error
  end
end
