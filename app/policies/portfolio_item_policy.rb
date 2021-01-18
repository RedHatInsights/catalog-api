class PortfolioItemPolicy < ApplicationPolicy
  attr_reader :error_message

  def index?
    rbac_access.permission_check('read', Portfolio)
  end

  def create?
    build_error_message(__method__)
    update_portfolio_check
  end

  def update?
    build_error_message(__method__)
    update_portfolio_check
  end

  def show?
    build_error_message(__method__)
    rbac_access.resource_check('read', @record.portfolio_id, Portfolio)
  end

  def destroy?
    build_error_message(__callee__)
    update_portfolio_check
  end

  alias restore? destroy?

  def copy?
    destination_id = @user.try(:params).try(:dig, :portfolio_id) || @record.portfolio_id

    if destination_id == @record.portfolio_id
      can_read_and_update_destination?(destination_id)
    else
      rbac_access.resource_check('read', @record.portfolio_id, Portfolio) &&
        can_read_and_update_destination?(destination_id)
    end
  end

  def edit_survey?
    build_error_message(__method__)
    update_portfolio_check
  end

  def set_approval?
    update_portfolio_check &&
      rbac_access.approval_workflow_check
  end

  alias tag? set_approval?
  alias untag? set_approval?

  def set_order_process?
    rbac_access.admin_access_check("order_processes", "read") &&
      rbac_access.admin_access_check("order_processes", "link") &&
      rbac_access.admin_access_check("order_processes", "unlink")
  end

  private

  def build_error_message(action)
    @error_message = "You are not authorized to perform the #{action.to_s.delete_suffix('?')} action for this portfolio item"
  end

  def can_read_and_update_destination?(destination_id)
    rbac_access.resource_check('read', destination_id, Portfolio) &&
      rbac_access.resource_check('update', destination_id, Portfolio)
  end

  def portfolio_id
    @record.class == Portfolio ? @record.id : @record.portfolio_id
  end

  class Scope < Scope
    def resolve
      if access_scopes.include?('admin')
        scope.all
      elsif access_scopes.include?('group')
        ids = Catalog::RBAC::AccessControlEntries.new(@user_context.group_uuids).ace_ids('read', Portfolio)
        scope.where(:portfolio_id => ids)
      elsif access_scopes.include?('user')
        scope.by_owner
      else
        Rails.logger.debug("Scope search for #{scope.table_name}")
        Rails.logger.debug("Scope does not include admin, group, or user. List of scopes: #{access_scopes}")
        raise Catalog::NotAuthorized, "Not Authorized for #{scope.table_name}"
      end
    end
  end
end
