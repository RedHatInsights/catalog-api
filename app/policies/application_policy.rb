class ApplicationPolicy
  include Api::V1x0::Mixins::ACEMixin

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
      if access_scopes.include?('admin')
        scope.all
      elsif access_scopes.include?('group')
        ids = Catalog::RBAC::AccessControlEntries.new(@user_context.group_uuids).ace_ids('read', scope)
        scope.where(:id => ids)
      elsif access_scopes.include?('user')
        scope.by_owner
      else
        Rails.logger.error("Error in scope search for #{scope.table_name}")
        Rails.logger.error("Scope does not include admin, group, or user. List of scopes: #{access_scopes}")
        raise Catalog::NotAuthorized, "Not Authorized for #{scope.table_name}"
      end
    end

    private

    def access_scopes
      @access_scopes ||= @user_context.access.scopes(scope.table_name, 'read')
    end
  end
end
