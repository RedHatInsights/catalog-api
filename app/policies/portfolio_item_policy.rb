class PortfolioItemPolicy < ApplicationPolicy
  def create?
    create_access_check

    true
  end

  def update?
    update_access_check

    true
  end

  def destroy?
    delete_access_check

    true
  end

  def copy?
    resource_check('read', @record.id)
    permission_check('create', Portfolio)
    permission_check('update', Portfolio)

    true
  end

  class Scope < Scope
    def resolve
      if catalog_administrator?
        scope.all
      else
        check_access

        ids = ace_ids('read', Portfolio)
        scope.where(:portfolio_id => ids)
      end
    end

    private

    def check_access
      access_obj = Insights::API::Common::RBAC::Access.new('portfolios', 'read').process
      raise Catalog::NotAuthorized, "Not Authorized for portfolios" unless access_obj.accessible?
    end
  end
end
