class ServicePlanPolicy < ApplicationPolicy
  attr_reader :error_message

  def create?
    build_error_message(__method__)
    rbac_access.resource_check("update", @record.id, Portfolio)
  end

  def update_modified?
    build_error_message(__callee__)
    update_portfolio_check
  end

  alias reset? update_modified?

  private

  def build_error_message(action)
    @error_message = "You are not authorized to perform the #{action.to_s.delete_suffix('?')} action for this service plan"
  end

  def portfolio_id
    @record.portfolio_item.portfolio_id
  end
end
