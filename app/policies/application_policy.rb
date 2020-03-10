class ApplicationPolicy
  include Api::V1::Mixins::ACEMixin
  include Api::V1::Mixins::RBACMixin

  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  alias new? create?

  def update?
    false
  end

  alias edit? update?

  def destroy?
    false
  end

  def user_capabilities
    capabilities = {}
    (self.class.instance_methods(false) - [:user_capabilities]).each do |method|
      capabilities[method.to_s.delete_suffix('?')] = self.send(method)
    end

    capabilities
  end

  private

  def rbac_access
    @rbac_access ||= Catalog::RBAC::Access.new(@user)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all # Override in sub-policy scope for now
    end

    def rbac_access
      @rbac_access ||= Catalog::RBAC::Access.new(@user)
    end

    private

    def catalog_administrator?
      Catalog::RBAC::Role.catalog_administrator?
    end
  end
end
