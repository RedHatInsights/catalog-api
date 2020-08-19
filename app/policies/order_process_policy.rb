class OrderProcessPolicy < ApplicationPolicy
  def show?
    rbac_access.read_access_check
  end

  def create?
    rbac_access.create_access_check(OrderProcess)
  end

  def update?
    rbac_access.update_access_check
  end

  def link?
    rbac_access.link_access_check
  end

  def unlink?
    rbac_access.unlink_access_check
  end

  def destroy?
    rbac_access.destroy_access_check
  end

  alias tag? link?
  alias untag? unlink?

  class Scope < Scope
    def resolve
      if access_scopes.include?('admin')
        scope.all
      else
        Rails.logger.debug("Scope search for #{scope.table_name.humanize}")
        raise Catalog::NotAuthorized, "Not Authorized for #{scope.table_name.humanize}"
      end
    end
  end
end
