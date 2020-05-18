class TenantPolicy < ApplicationPolicy
  def update?
    rbac_access.permission_check('update')
  end

  def show?
    rbac_access.permission_check('read')
  end
end
