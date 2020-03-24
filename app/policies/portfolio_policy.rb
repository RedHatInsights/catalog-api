class PortfolioPolicy < ApplicationPolicy
  def create?
    rbac_access.admin_check
  end

  alias destroy? create?
  alias copy? create?
  alias share? create?
  alias unshare? create?

  def show?
    rbac_access.read_access_check
  end

  def update?
    rbac_access.update_access_check
  end

  def set_approval?
    # TODO: Add "Approval Administrator" check as &&
    rbac_access.update_access_check
  end

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
