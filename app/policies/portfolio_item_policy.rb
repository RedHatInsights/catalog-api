class PortfolioItemPolicy < PortfolioDescendantPolicy
  ADMINISTRATOR_ROLE_NAME = 'Catalog Administrator'.freeze
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def catalog_admin?
      @admin ||= Insights::API::Common::RBAC::Roles.assigned_role?(ADMINISTRATOR_ROLE_NAME)
    end

    def resolve
      if catalog_admin?
        scope.all
      else
        access_obj = Insights::API::Common::RBAC::Access.new('portfolios', 'read').process
        raise Catalog::NotAuthorized, "Not Authorized for portfolios" unless access_obj.accessible?
        ids = ace_ids('read', Portfolio)
        scope.where(:portfolio_id => ids)
      end
    end
  end
end
