class PortfolioPolicy < ApplicationPolicy
  def create?
    rbac_access.create_access_check
  end

  def destroy?
    rbac_access.destroy_access_check
  end

  def show?
    rbac_access.read_access_check
  end

  def update?
    rbac_access.update_access_check
  end

  def copy?
    rbac_access.resource_check('read', @record.id) &&
      rbac_access.create_access_check &&
      rbac_access.resource_check('update', @record.id)
  end

  def share?
    rbac_access.admin_check
  end

  alias unshare? share?

  class Scope < Scope
    def resolve
      if catalog_administrator?
        scope.all
      else
        ids = Catalog::RBAC::AccessControlEntries.new.ace_ids('read', Portfolio)
        scope.where(:id => ids)
      end
    end
  end
end
