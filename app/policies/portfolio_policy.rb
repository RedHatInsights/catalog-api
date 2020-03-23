class PortfolioPolicy < ApplicationPolicy
  def create?
    rbac_access.create_access_check
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

  class Scope < Scope
    def resolve
      if user.catalog_access.admin_scope?(Portfolio, 'read', ENV['APP_NAME'])
        scope.all
      else
        ids = Catalog::RBAC::AccessControlEntries.new.ace_ids('read', Portfolio)
        scope.where(:id => ids)
      end
    end
  end
end
