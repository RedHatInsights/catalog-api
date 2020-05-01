class ServicePlanPolicy < ApplicationPolicy
  def create?
    rbac_access.resource_check("update", @record.id, Portfolio)
  end

  def update_modified?
    update_portfolio_check
  end

  alias reset? update_modified?

  private

  def portfolio_id
    @record.portfolio_item.portfolio_id
  end
end
