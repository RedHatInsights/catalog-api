class ServicePlanPolicy < ApplicationPolicy
  def create?
    rbac_access.resource_check("update", @record.id, Portfolio)
  end

  def update_modified?
    rbac_access.resource_check("update", @record.portfolio_item.portfolio_id, Portfolio)
  end

  alias reset? update_modified?
end
