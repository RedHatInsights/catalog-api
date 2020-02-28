class PortfolioItemPolicy < ApplicationPolicy
  def index?
    rbac_access.permission_check('read', Portfolio)
  end

  def create?
    rbac_access.resource_check('update', @record.id, Portfolio)
  end

  def update?
    rbac_access.update_access_check
  end

  def destroy?
    rbac_access.destroy_access_check
  end

  def copy?
    rbac_access.resource_check('read', @record.id) &&
      rbac_access.permission_check('create', Portfolio) &&
      rbac_access.permission_check('update', Portfolio)
  end

  class Scope < Scope
    def resolve
      if Catalog::RBAC::Role.catalog_administrator?
        scope.all
      else
        ids = Catalog::RBAC::AccessControlEntries.new.ace_ids('read', Portfolio)
        scope.where(:portfolio_id => ids)
      end
    end
  end
end
