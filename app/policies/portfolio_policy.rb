class PortfolioPolicy < ApplicationPolicy
  def create?
    rbac_access.create_access_check
  end

  alias copy? create?

  def destroy?
    rbac_access.destroy_access_check
  end

  def show?
    rbac_access.read_access_check
  end

  def update?
    rbac_access.update_access_check
  end

  alias share? update?
  alias unshare? update?

  # def set_approval?
  #   # TODO: Add "Approval Administrator" check as &&
  #   rbac_access.update_access_check
  # end

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
