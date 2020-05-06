class OrderPolicy < ApplicationPolicy
  def show?
    rbac_access.read_access_check
  end

  def submit_order?
    order_items_check = @record.order_items.collect do |order_item|
      rbac_access.resource_check('order', order_item.portfolio_item.portfolio_id, Portfolio)
    end

    order_items_check.all?
  end

  class Scope < Scope
    def resolve
      if access_scopes.include?('admin')
        scope.all
      elsif access_scopes.include?('user')
        scope.by_owner
      else
        Rails.logger.debug("Error in scope search for #{scope.table_name}")
        Rails.logger.debug("Scope does not include admin, group, or user. List of scopes: #{access_scopes}")
        raise Catalog::NotAuthorized, "Not Authorized for #{scope.table_name}"
      end
    end
  end
end
