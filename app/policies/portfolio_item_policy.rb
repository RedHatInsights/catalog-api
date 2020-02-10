class PortfolioItemPolicy < ApplicationPolicy
  def create?
    rbac_access.resource_check('update', @record.id, Portfolio)

    true
  end

  def update?
    rbac_access.update_access_check

    true
  end

  def destroy?
    rbac_access.destroy_access_check

    true
  end

  def copy?
    rbac_access.resource_check('read', @record.id)
    rbac_access.permission_check('create', Portfolio)
    rbac_access.permission_check('update', Portfolio)

    true
  end

  class Scope < Scope
    def resolve
      if Catalog::RBAC::Role.catalog_administrator?
        scope.all
      else
        rbac_access.permission_check('read', Portfolio)

        ids = Catalog::RBAC::AccessControlEntries.new.ace_ids('read', Portfolio)
        scope.where(:portfolio_id => ids)
      end
    end
  end
end
