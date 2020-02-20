class PortfolioPolicy < ApplicationPolicy
  def create?
    rbac_access.create_access_check

    true
  end

  def destroy?
    rbac_access.destroy_access_check

    true
  end

  def show?
    rbac_access.read_access_check

    true
  end

  def update?
    rbac_access.update_access_check

    true
  end

  def copy?
    rbac_access.resource_check('read', @record.id)
    rbac_access.permission_check('create')
    rbac_access.permission_check('update')

    true
  end

  def share?
    rbac_access.admin_check

    true
  end

  def unshare?
    rbac_access.admin_check

    true
  end
end
