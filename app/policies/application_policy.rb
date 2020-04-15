class ApplicationPolicy
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
    (self.class.instance_methods(false) - [:user_capabilities, :index?]).each do |method|
      capabilities[method.to_s.delete_suffix('?')] = self.send(method)
    end

    capabilities
  end

  private

  def rbac_access
    @rbac_access ||= Catalog::RBAC::Access.new(@user, @record)
  end

  class Scope
    attr_reader :user_context, :scope

    def initialize(user_context, scope)
      @user_context = user_context
      @scope = scope
    end

    def resolve
      scope.all
    end

    private

    def access_scopes
      @access_scopes ||= @user_context.access.scopes(scope.table_name, 'read')
    end
  end
end
